# deploy_cloud_run.ps1
$PROJECT_ID = "ai-seekho-2026-493112"
$SERVICE_NAME = "sahulat-ai-backend"
$REGION = "us-central1"

Write-Host "🚀 Deploying $SERVICE_NAME to Cloud Run in $PROJECT_ID..." -ForegroundColor Cyan

gcloud run deploy $SERVICE_NAME `
    --source . `
    --project $PROJECT_ID `
    --region $REGION `
    --allow-unauthenticated `
    --port 8080 `
    --set-env-vars "GOOGLE_API_KEY=$($env:GOOGLE_API_KEY)"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Deployment successful!" -ForegroundColor Green
} else {
    Write-Host "❌ Deployment failed." -ForegroundColor Red
}
