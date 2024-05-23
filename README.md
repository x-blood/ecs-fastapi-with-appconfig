## commands

### run local

```bash
cd app && uvicorn main:app --reload
```

### Environment Variables

```bash
export $(cat .env| grep -v "#" | xargs)
```

### run on AWS

```bash
make tf_apply
make create_pull_through_cache
make app_build_and_push
make ecspresso_deploy
```

### de-provisioning on AWS

```bash
make ecspresso_delete
make ecr_clean
make tf_destroy
```
