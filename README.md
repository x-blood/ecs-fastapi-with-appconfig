## commands

### run local****

```bash
cd app && uvicorn main:app --reload
```

### Environment Variables

```bash
export $(cat .env| grep -v "#" | xargs)
```
