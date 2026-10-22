# Campus Teams — deploy-ready registration app

A minimal white/navy web app for student game sign-ups. Supports capacity limits, auto-closing at capacity, multiple event/registration rounds, organizer list view, CSV export, QR code generation, and randomized 2/3/4-team splitting.

## Important
This is a deployable source package, not a live hosted website yet. A real public link requires a hosting account and a Supabase project. QR codes use the final website URL directly (no QR redirect service); deploy first, then generate/download the QR from the organizer dashboard.

## 1. Create the database
1. Create a project at https://supabase.com/
2. In **SQL Editor**, run the full contents of `schema.sql`.
3. Go to **Authentication → Users** and create the organizer user with email/password.
4. Copy that user's UUID. In SQL Editor run:
   ```sql
   insert into public.organizers(user_id) values ('PASTE-ORGANIZER-USER-UUID');
   ```
5. Open **Project Settings → API** and copy the Project URL and anon/public key.

## 2. Configure the app
Open `index.html`. Near the top of the script, replace:
```js
const CONFIG={SUPABASE_URL:"YOUR_SUPABASE_PROJECT_URL",SUPABASE_ANON_KEY:"YOUR_SUPABASE_ANON_KEY"};
```
with your project URL and anon/public key. Never put a Supabase `service_role` secret in this file.

## 3. Deploy it
1. Create a GitHub repository and upload `index.html`, `schema.sql`, and this README.
2. Sign in to https://vercel.com/ and import the repository, or use https://pages.cloudflare.com/.
3. For a plain HTML project, no build command is needed; set the output/root directory to the repository root.
4. Open the deployed HTTPS URL and test one event before sharing it.

## 4. Use it
- Organizer: tap **Organizer**, sign in, create a registration, set the capacity, and choose 2, 3, or 4 teams.
- View list: use **View list** to see registered students, remaining spaces, download CSV, generate QR PNG, or split into teams.
- Student: scanning the QR opens the exact deployed site with the selected game ID in the URL.
- Each new registration round is a separate game and has its own capacity/list/QR.
- A registration closes automatically when it reaches capacity; organizers can also close/reopen it manually.

## Notes / limitations to address before broad use
- The organizer should test the project with fake students first.
- Student names and majors are personal data. Share lists only with authorized organizers; avoid collecting student email unless needed.
- Team splits are randomized in the current page and are not saved as a permanent team assignment.
- This starter does not provide student identity verification. For a school-wide production deployment, consider requiring school email or adding an approved login.
- Review Supabase RLS policies and test with a non-organizer account before launch.
