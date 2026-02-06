#!/usr/bin/env python3
"""
Build Orchestrator - Manage builds across multiple remote servers

Usage:
    ./orchestrator.py pipeline.yaml
    ./orchestrator.py --status
    ./orchestrator.py --cancel <job-id>
"""

import subprocess
import json
import time
import yaml
import argparse
import sys
from dataclasses import dataclass, field
from typing import List, Dict, Optional
from pathlib import Path
from datetime import datetime

@dataclass
class Task:
    name: str
    server: str
    command: str
    workdir: str = "~"
    depends_on: List[str] = field(default_factory=list)
    timeout: int = 7200  # 2 hours default
    status: str = "pending"
    pid: Optional[int] = None
    log_file: Optional[str] = None
    start_time: Optional[float] = None
    end_time: Optional[float] = None
    result: Optional[str] = None


class Orchestrator:
    def __init__(self, config_path: str = "~/.build-orchestrator/config.yaml"):
        self.tasks: Dict[str, Task] = {}
        self.config = self._load_config(config_path)
        self.job_id = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.state_file = Path(f"/tmp/orchestrator-{self.job_id}.json")
        
    def _load_config(self, path: str) -> dict:
        """Load orchestrator config"""
        config_path = Path(path).expanduser()
        if config_path.exists():
            with open(config_path) as f:
                return yaml.safe_load(f)
        return {"servers": {}, "notifications": {}, "defaults": {}}
    
    def _ssh_cmd(self, server: str, command: str, capture: bool = True) -> subprocess.CompletedProcess:
        """Execute SSH command"""
        ssh_cmd = f"ssh -o ConnectTimeout=10 -o BatchMode=yes {server} '{command}'"
        return subprocess.run(ssh_cmd, shell=True, capture_output=capture, text=True)
    
    def load_pipeline(self, path: str):
        """Load pipeline from YAML file"""
        with open(path) as f:
            pipeline = yaml.safe_load(f)
        
        for stage in pipeline.get("stages", []):
            task = Task(
                name=stage["name"],
                server=stage["server"],
                command=stage["command"],
                workdir=stage.get("workdir", "~"),
                depends_on=stage.get("depends_on", []),
                timeout=self._parse_timeout(stage.get("timeout", "2h"))
            )
            self.tasks[task.name] = task
        
        print(f"📋 Loaded {len(self.tasks)} tasks from {path}")
    
    def _parse_timeout(self, timeout: str) -> int:
        """Parse timeout string (e.g., '2h', '30m') to seconds"""
        if isinstance(timeout, int):
            return timeout
        if timeout.endswith("h"):
            return int(timeout[:-1]) * 3600
        if timeout.endswith("m"):
            return int(timeout[:-1]) * 60
        return int(timeout)
    
    def start_task(self, task: Task):
        """Start task on remote server"""
        print(f"🚀 Starting: {task.name} on {task.server}")
        
        timestamp = int(time.time())
        task.log_file = f"/tmp/build-{task.name}-{timestamp}.log"
        task.start_time = time.time()
        
        # Start command in background with nohup
        remote_cmd = f"cd {task.workdir} && nohup {task.command} > {task.log_file} 2>&1 & echo $!"
        result = self._ssh_cmd(task.server, remote_cmd)
        
        if result.returncode == 0 and result.stdout.strip():
            task.pid = int(result.stdout.strip())
            task.status = "running"
            print(f"   PID: {task.pid}, Log: {task.log_file}")
        else:
            task.status = "failed"
            task.result = "failed to start"
            print(f"   ❌ Failed to start: {result.stderr}")
        
        self._save_state()
    
    def check_status(self, task: Task) -> str:
        """Check if task is still running"""
        if not task.pid:
            return "unknown"
        
        result = self._ssh_cmd(task.server, f"ps -p {task.pid} > /dev/null 2>&1 && echo running || echo done")
        return result.stdout.strip() if result.returncode == 0 else "unknown"
    
    def get_result(self, task: Task) -> str:
        """Get task result by checking log file"""
        if not task.log_file:
            return "unknown"
        
        # Check for common success/failure patterns
        check_cmd = f"""
            if grep -qE 'SUCCESS|Build completed|All tests passed' {task.log_file} 2>/dev/null; then
                echo success
            elif grep -qE 'ERROR|FAILED|Build failed' {task.log_file} 2>/dev/null; then
                echo failed
            else
                echo unknown
            fi
        """
        result = self._ssh_cmd(task.server, check_cmd)
        return result.stdout.strip() if result.returncode == 0 else "unknown"
    
    def get_log_tail(self, task: Task, lines: int = 5) -> str:
        """Get last N lines of task log"""
        if not task.log_file:
            return ""
        result = self._ssh_cmd(task.server, f"tail -{lines} {task.log_file} 2>/dev/null")
        return result.stdout if result.returncode == 0 else ""
    
    def notify(self, message: str, level: str = "info"):
        """Send notification (placeholder - integrate with OpenClaw)"""
        emoji = {"info": "ℹ️", "success": "✅", "error": "❌", "warning": "⚠️"}.get(level, "📢")
        print(f"{emoji} {message}")
        
        # TODO: Integrate with OpenClaw message tool
        # Example: subprocess.run(["openclaw", "message", "--send", message])
    
    def _save_state(self):
        """Save current state to file"""
        state = {
            "job_id": self.job_id,
            "tasks": {
                name: {
                    "status": task.status,
                    "server": task.server,
                    "pid": task.pid,
                    "log_file": task.log_file,
                    "start_time": task.start_time,
                    "end_time": task.end_time,
                    "result": task.result
                }
                for name, task in self.tasks.items()
            }
        }
        with open(self.state_file, "w") as f:
            json.dump(state, f, indent=2)
    
    def run(self):
        """Run the pipeline"""
        self.notify(f"Pipeline started: {self.job_id} ({len(self.tasks)} tasks)")
        start_time = time.time()
        
        try:
            while True:
                pending = [t for t in self.tasks.values() if t.status == "pending"]
                running = [t for t in self.tasks.values() if t.status == "running"]
                done = [t for t in self.tasks.values() if t.status in ("done", "failed")]
                
                # Start pending tasks with satisfied dependencies
                for task in pending:
                    deps_satisfied = all(
                        self.tasks[d].status == "done" and self.tasks[d].result == "success"
                        for d in task.depends_on
                    )
                    deps_failed = any(
                        self.tasks[d].result == "failed"
                        for d in task.depends_on
                        if d in self.tasks
                    )
                    
                    if deps_failed:
                        task.status = "skipped"
                        task.result = "dependency failed"
                        print(f"⏭️  Skipping {task.name}: dependency failed")
                    elif deps_satisfied:
                        self.start_task(task)
                
                # Check running tasks
                for task in running:
                    status = self.check_status(task)
                    
                    if status == "done":
                        task.end_time = time.time()
                        task.result = self.get_result(task)
                        task.status = "done"
                        
                        duration = task.end_time - task.start_time
                        emoji = "✅" if task.result == "success" else "❌"
                        print(f"{emoji} {task.name}: {task.result} ({duration/60:.1f}min)")
                        
                        if task.result != "success":
                            print(f"   Last log lines:")
                            for line in self.get_log_tail(task).split("\n"):
                                print(f"   | {line}")
                    
                    elif status == "running":
                        # Check timeout
                        elapsed = time.time() - task.start_time
                        if elapsed > task.timeout:
                            print(f"⏰ Timeout: {task.name} ({elapsed/60:.0f}min > {task.timeout/60:.0f}min)")
                            self._ssh_cmd(task.server, f"kill {task.pid} 2>/dev/null")
                            task.status = "done"
                            task.result = "timeout"
                            task.end_time = time.time()
                
                self._save_state()
                
                # Check if all done
                if all(t.status in ("done", "failed", "skipped") for t in self.tasks.values()):
                    break
                
                # Print status
                print(f"\r⏳ Running: {len(running)}, Pending: {len(pending)}, Done: {len(done)}", end="", flush=True)
                time.sleep(30)
            
            # Final summary
            total_time = time.time() - start_time
            success = sum(1 for t in self.tasks.values() if t.result == "success")
            failed = sum(1 for t in self.tasks.values() if t.result in ("failed", "timeout"))
            
            print(f"\n\n{'='*50}")
            print(f"Pipeline Complete: {self.job_id}")
            print(f"Duration: {total_time/60:.1f} minutes")
            print(f"Results: {success} success, {failed} failed")
            print(f"{'='*50}")
            
            if failed > 0:
                self.notify(f"Pipeline failed: {failed} tasks failed", "error")
                return 1
            else:
                self.notify(f"Pipeline complete: {success} tasks succeeded", "success")
                return 0
                
        except KeyboardInterrupt:
            print("\n\n⚠️  Interrupted! Cleaning up...")
            for task in self.tasks.values():
                if task.status == "running" and task.pid:
                    print(f"   Killing {task.name} (PID {task.pid})")
                    self._ssh_cmd(task.server, f"kill {task.pid} 2>/dev/null")
            return 130


def main():
    parser = argparse.ArgumentParser(description="Build Orchestrator")
    parser.add_argument("pipeline", nargs="?", help="Pipeline YAML file")
    parser.add_argument("--status", action="store_true", help="Show current status")
    parser.add_argument("--cancel", metavar="JOB_ID", help="Cancel a running job")
    parser.add_argument("--config", default="~/.build-orchestrator/config.yaml", help="Config file path")
    
    args = parser.parse_args()
    
    if args.status:
        # Show status of recent jobs
        for state_file in sorted(Path("/tmp").glob("orchestrator-*.json"), reverse=True)[:5]:
            with open(state_file) as f:
                state = json.load(f)
            print(f"\n{state['job_id']}:")
            for name, task in state["tasks"].items():
                print(f"  {name}: {task['status']} ({task.get('result', 'N/A')})")
        return 0
    
    if args.cancel:
        state_file = Path(f"/tmp/orchestrator-{args.cancel}.json")
        if state_file.exists():
            with open(state_file) as f:
                state = json.load(f)
            for name, task in state["tasks"].items():
                if task["status"] == "running" and task.get("pid"):
                    print(f"Killing {name} on {task['server']}")
                    subprocess.run(f"ssh {task['server']} 'kill {task['pid']}' 2>/dev/null", shell=True)
            print("Cancelled.")
        return 0
    
    if not args.pipeline:
        parser.print_help()
        return 1
    
    orchestrator = Orchestrator(args.config)
    orchestrator.load_pipeline(args.pipeline)
    return orchestrator.run()


if __name__ == "__main__":
    sys.exit(main())
