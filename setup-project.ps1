# PowerShell script to set up the managertask project

Write-Host "Setting up managertask project..." -ForegroundColor Green

# Copy .env file
Copy-Item .env.example .env -Force

# Setup Backend
Set-Location backend
Write-Host "Installing backend dependencies..." -ForegroundColor Yellow
npm install

Write-Host "Generating Prisma client..." -ForegroundColor Yellow
npx prisma generate

Write-Host "Running database migrations..." -ForegroundColor Yellow
npx prisma migrate dev --name init

Write-Host "Seeding database..." -ForegroundColor Yellow
npm run seed

Set-Location ..

# Setup Frontend
Set-Location frontend
Write-Host "Installing frontend dependencies..." -ForegroundColor Yellow
npm install

Set-Location ..

Write-Host "Project setup complete!" -ForegroundColor Green
Write-Host "Run 'docker-compose up -d' to start all services" -ForegroundColor Cyan