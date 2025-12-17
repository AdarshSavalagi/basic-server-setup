Login to minio using mc client

```bash
mc alias set local url \
  MINIO_ROOT_USER \
  MINIO_ROOT_PASSWORD
```

### create bucket using
```bash
mc mb local/public-assets
```

### make bucket access public
```bash
mc anonymous set download local/public-assets
```
