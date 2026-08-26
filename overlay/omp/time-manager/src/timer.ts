export interface DurationSnapshot {
  taskMs?: number;
  totalMs?: number;
  active: boolean;
}

export class DurationTracker {
  private promptStartedAt?: number;
  private promptFinishedAt?: number;
  private callStartedAt?: number;
  private callFinishedAt?: number;

  startPrompt(now: number): void {
    this.promptStartedAt = now;
    this.promptFinishedAt = undefined;
    this.callStartedAt = undefined;
    this.callFinishedAt = undefined;
  }

  ensurePrompt(now: number): void {
    if (this.promptStartedAt === undefined || this.promptFinishedAt !== undefined) this.startPrompt(now);
  }

  startCall(now: number): void {
    this.ensurePrompt(now);
    this.callStartedAt = now;
    this.callFinishedAt = undefined;
  }

  finishCall(now: number): void {
    if (this.callStartedAt !== undefined && this.callFinishedAt === undefined) this.callFinishedAt = now;
  }

  finishPrompt(now: number): void {
    if (this.promptStartedAt === undefined || this.promptFinishedAt !== undefined) return;
    this.finishCall(now);
    this.promptFinishedAt = now;
  }

  snapshot(now: number): DurationSnapshot {
    const active = this.promptStartedAt !== undefined && this.promptFinishedAt === undefined;
    const totalEnd = this.promptFinishedAt ?? now;
    const callEnd = this.callFinishedAt ?? now;
    return {
      active,
      ...(this.promptStartedAt === undefined ? {} : {totalMs: Math.max(0, totalEnd - this.promptStartedAt)}),
      ...(this.callStartedAt === undefined ? {} : {taskMs: Math.max(0, callEnd - this.callStartedAt)}),
    };
  }
}

export function formatDuration(milliseconds: number): string {
  const seconds = Math.floor(milliseconds / 1000);
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const remainder = seconds % 60;
  return hours > 0
    ? `${hours}:${minutes.toString().padStart(2, "0")}:${remainder.toString().padStart(2, "0")}`
    : `${minutes}:${remainder.toString().padStart(2, "0")}`;
}

export function formatStatus(snapshot: DurationSnapshot): string | undefined {
  if (snapshot.totalMs === undefined) return undefined;
  const total = `Total ${formatDuration(snapshot.totalMs)}`;
  return snapshot.taskMs === undefined ? total : `${total} · Task ${formatDuration(snapshot.taskMs)}`;
}
