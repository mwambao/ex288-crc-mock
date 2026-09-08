# Self-marking the mock exam

`scripts/mark.sh` is a **read-only** marker. It checks the resources and observable outcomes left in CRC after you answer a question. It does not repair, create, patch, scale, delete, or otherwise change your answer.

Run it from the root of the mock repository while logged in to OpenShift as `developer`:

```bash
./scripts/mark.sh 5
```

Mark several selected questions:

```bash
./scripts/mark.sh 1 3 7 13
```

Mark a range:

```bash
./scripts/mark.sh 1-5
```

Mark the complete mock:

```bash
./scripts/mark.sh all
```

Each check reports `PASS`, `FAIL`, or `WARN`. A question is `PASS` when all automatically verifiable required checks pass. It is `PASS WITH WARNING` when the observable answer is correct but at least one part cannot be proven from cluster state. A question is `FAIL` when one or more required checks fail. The script exits with status `0` when all selected questions pass and status `1` when at least one selected question fails.

## Why warnings exist

Some EX288-style actions leave no reliable evidence of *how* you performed them. For example, Q11 requires you to scale from the OpenShift web console; the marker can prove that the Deployment ended at two ready replicas, but not that you clicked the console rather than running `oc scale`. Likewise, Q2 can prove that the image tag exists in the OpenShift registry, but a later script cannot prove that you personally pulled the image back to Podman on your workstation.

Treat a warning as a manual checklist item, not as permission to skip the requirement during a timed practice attempt.

## Recommended workflow

Before an attempt, use `scripts/setup.sh`. Answer the question without opening `SOLUTIONS.md`. When finished, run `scripts/mark.sh <question>`. Read only the feedback from the marker first. If it fails, troubleshoot the cluster yourself and rerun the marker. Open `SOLUTIONS.md` only after you are genuinely stuck or when reviewing the completed attempt.

For a full mock, answer all 15 questions first and then run:

```bash
./scripts/mark.sh all
```

This preserves the exam-like experience and gives you one final result summary.
