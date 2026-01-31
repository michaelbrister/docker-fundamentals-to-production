$ids = docker ps -a --filter "label=com.docker.compose.project=lab-08" --format "{{.ID}}"
if ($ids) {
  Write-Error "lab-08 containers still exist"
  exit 1
}
Write-Host "Lab 08 validation passed"
