# YTEmpire Web Interfaces Setup Guide

## Current Status

All services are running and accessible. You have two options to access them:

## Option 1: Direct Port Access (Works Immediately)

You can access all services right now using these URLs:

- **Frontend Application**: http://localhost:3000
- **Backend API**: http://localhost:5000
- **API Documentation**: http://localhost:5000/api-docs
- **pgAdmin**: http://localhost:8080
  - Email: `admin@ytempire.com` or `admin@example.com`
  - Password: `admin123`
- **MailHog**: http://localhost:8025

## Option 2: Use Local Domain Names (Requires Hosts File Setup)

To use the cleaner `.local` domain names, you need to configure your Windows hosts file.

### Step 1: Run the Setup Script

1. Open Command Prompt as Administrator:
   - Press `Win + X`
   - Select "Windows Terminal (Admin)" or "Command Prompt (Admin)"

2. Navigate to the project directory:
   ```cmd
   cd C:\Users\PC\projects\my_projects\_ytempire
   ```

3. Run the hosts setup script:
   ```cmd
   scripts\setup-hosts.bat
   ```

### Step 2: Access Services via Domain Names

After running the script, you can access:

- **Application**: http://ytempire.local
- **API Documentation**: http://api.ytempire.local/docs
- **pgAdmin**: http://pgadmin.ytempire.local
  - Email: `admin@ytempire.com`
  - Password: `admin123`
- **MailHog**: http://mailhog.ytempire.local

### Manual Hosts File Setup (Alternative)

If the script doesn't work, you can manually edit the hosts file:

1. Open Notepad as Administrator
2. Open file: `C:\Windows\System32\drivers\etc\hosts`
3. Add these lines at the end:
   ```
   # YTEmpire Local Development
   127.0.0.1    ytempire.local
   127.0.0.1    api.ytempire.local
   127.0.0.1    pgadmin.ytempire.local
   127.0.0.1    mailhog.ytempire.local
   ```
4. Save the file
5. Open Command Prompt and run: `ipconfig /flushdns`

## Nginx Configuration

The nginx reverse proxy has been configured to handle all these domains and route traffic to the appropriate services:

- `ytempire.local` → Frontend (port 3000)
- `api.ytempire.local` → Backend API (port 5000)
- `pgadmin.ytempire.local` → pgAdmin (port 8080)
- `mailhog.ytempire.local` → MailHog (port 8025)

## Troubleshooting

### If domains don't work:

1. **Check hosts file**: Ensure the entries were added correctly
2. **Clear DNS cache**: Run `ipconfig /flushdns` in Command Prompt
3. **Check browser cache**: Try in an incognito/private window
4. **Firewall**: Ensure Windows Firewall isn't blocking port 80

### If services are not accessible:

1. **Check containers are running**:
   ```bash
   docker ps
   ```

2. **Check nginx logs**:
   ```bash
   docker logs ytempire-nginx
   ```

3. **Restart nginx**:
   ```bash
   docker restart ytempire-nginx
   ```

## Service Credentials

### pgAdmin
- **Email**: `admin@ytempire.com`
- **Password**: `admin123`
- **Database Connection**:
  - Host: `postgresql` (internal) or `localhost` (external)
  - Port: `5432`
  - Username: `ytempire_user`
  - Password: `ytempire_pass`
  - Database: `ytempire_dev`

### Test User Accounts (in database)
- **Admin**: 
  - Email: `admin@ytempire.com`
  - Username: `admin`
  - Password: `password123`
- **Creator**:
  - Email: `creator@ytempire.com`
  - Username: `testcreator`
  - Password: `password123`