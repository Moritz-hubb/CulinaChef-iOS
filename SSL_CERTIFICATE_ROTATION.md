# SSL Certificate Rotation Guide

## ✅ Completed Steps

1. **Removed certificates from Git repository**
   - Added `*.cer`, `*.p12`, `*.mobileprovision` to `.gitignore`
   - Removed certificates from Git index (committed)
   - Certificates remain locally for builds

2. **Downloaded new backend certificate**
   - Backend certificate successfully downloaded
   - Location: `Certificates/backend.cer` and `backend.cer`

3. **Created helper scripts**
   - `scripts/download_ssl_certificates.sh` - Downloads certificates from servers
   - `scripts/cleanup_certificates_from_history.sh` - Removes certificates from Git history

## ⚠️ Remaining Steps

### 1. Download Supabase Certificate

The Supabase certificate download failed because the URL is a placeholder. You need to:

```bash
cd ios
SUPABASE_URL=https://YOUR-ACTUAL-PROJECT.supabase.co ./scripts/download_ssl_certificates.sh
```

Or edit the script and set the `SUPABASE_URL` variable directly.

### 2. Verify Certificates

After downloading, verify the certificates are correct:

```bash
# Check Supabase certificate
openssl x509 -in Certificates/supabase.cer -inform DER -noout -subject -dates

# Check Backend certificate
openssl x509 -in Certificates/backend.cer -inform DER -noout -subject -dates
```

### 3. Rebuild and Test

1. Rebuild the iOS app in Xcode
2. Test that SSL pinning works correctly
3. Verify network requests succeed

### 4. Clean Git History (Optional but Recommended)

⚠️ **WARNING**: This rewrites Git history and requires force-push!

Only do this if:
- Repository is private, OR
- All collaborators are informed and can re-clone

```bash
cd ios
./scripts/cleanup_certificates_from_history.sh
```

After cleanup, force-push (if repository is private):
```bash
git push origin --force --all
git push origin --force --tags
```

**Important**: All collaborators must re-clone the repository after this!

## 📋 Certificate Locations

- `Certificates/supabase.cer` - Supabase SSL certificate
- `Certificates/backend.cer` - Backend SSL certificate
- `supabase.cer` - Symlink/copy for backward compatibility
- `backend.cer` - Symlink/copy for backward compatibility

All these files are now in `.gitignore` and will NOT be committed.

## 🔒 Security Notes

- Old certificates are still in Git history (8 commits found)
- For maximum security, clean Git history (see step 4 above)
- Certificates are now properly excluded from future commits
- SSL pinning will continue to work with new certificates

