# Testing Guide

**You do not need to be a developer to run these tests.**  
This guide walks you through every step from a brand-new computer to a green test run.

---

## What you are testing

The `eba_randomisation` package is the engine that decides whether a young person enrolled by a field agent is **eligible** for the EBA study, and if so, which **study group** they go into (Treatment, Control, or Waiting).

The tests verify:
- The eligibility rules work correctly (age, income, education level, etc.)
- The group assignment ratio is correct (roughly 2 Treatment for every 1 Control in Phase 1)
- Phase 1 transitions to Phase 2 at the right time
- The built-in database behaves correctly

You will **not** need a phone, an app, or an internet connection to run the tests.

---

## Step 1 — Install Dart

Dart is a free, lightweight programming language. You only need to install it once.

### On macOS

1. Open **Terminal** (press `Cmd + Space`, type `Terminal`, press Enter).
2. Paste the following command and press Enter:

   ```
   brew install dart
   ```

   > If you see `command not found: brew`, you need to install Homebrew first.  
   > Go to https://brew.sh and follow the one-line install command at the top of that page, then repeat this step.

3. When it finishes, verify the install worked:

   ```
   dart --version
   ```

   You should see something like: `Dart SDK version: 3.x.x`

### On Windows

1. Go to https://dart.dev/get-dart
2. Click **Download the Dart SDK for Windows**.
3. Unzip the downloaded file and move the `dart-sdk` folder somewhere permanent (e.g. `C:\dart-sdk`).
4. Add `C:\dart-sdk\bin` to your system PATH:
   - Search for **Environment Variables** in the Start menu.
   - Click **Environment Variables**, find **Path** under System variables, click Edit.
   - Click **New** and paste `C:\dart-sdk\bin`.
   - Click OK on all dialogs.
5. Open a new **Command Prompt** window and run:

   ```
   dart --version
   ```

### On Linux (Ubuntu / Debian)

```bash
sudo apt-get update
sudo apt-get install apt-transport-https
sudo sh -c 'wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'
sudo sh -c 'wget -qO- https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'
sudo apt-get update
sudo apt-get install dart
```

---

## Step 2 — Download the test package

### Option A — Using Git (recommended)

1. Install Git from https://git-scm.com if you don't already have it.
2. Open Terminal (macOS/Linux) or Command Prompt (Windows).
3. Run:

   ```
   git clone https://github.com/KalembaUG/eba_randomisation.git
   cd eba_randomisation
   ```

### Option B — Download as a ZIP

1. Go to https://github.com/KalembaUG/eba_randomisation
2. Click the green **Code** button → **Download ZIP**.
3. Unzip the file.
4. Open Terminal / Command Prompt and navigate into the unzipped folder:

   ```
   cd eba_randomisation-main
   ```

   (the folder name may include `-main` at the end)

---

## Step 3 — Install package dependencies

In the same Terminal window (you should be inside the `eba_randomisation` folder), run:

```
dart pub get
```

You should see output ending with `Got dependencies!`

This downloads the small libraries the package depends on. It only needs internet once — after that everything runs offline.

---

## Step 4 — Run the tests

```
dart test
```

### What a passing run looks like

```
00:02 +64: All tests passed!
```

The number `+64` means 64 individual checks all passed.

### What a failing run looks like

```
00:02 +62 -2: Some tests failed.
```

If any tests fail, the output will show exactly which check failed and what the actual vs expected values were. Please copy the full terminal output and send it to the development team.

---

## Understanding the test files

You don't need to read the code, but here is a plain-English description of what each test file checks:

| File | What it checks |
|------|---------------|
| `eligibility_test.dart` | Each of the 6 eligibility rules — does a 31-year-old get correctly rejected? Does someone who previously participated in Educate! get rejected? Etc. |
| `block_randomisation_test.dart` | Are groups assigned in the right pattern? After 3 assignments there should always be exactly 2 Treatment and 1 Control. After 300 assignments the ratio should be close to 2:1. |
| `phase_transition_test.dart` | Does the system switch from Phase 1 to Phase 2 at exactly the right count? Does it stop issuing assignments when both phases are complete? |
| `parish_config_test.dart` | Are the parish settings correct? Do the target calculation formulas give the right numbers? Are all 36 parishes in the list? |
| `sqflite_store_test.dart` | Does the built-in database correctly store and retrieve assignment counts? |

---

## Running a single test file

If you want to run just one file at a time:

```
dart test test/eligibility_test.dart
```

Replace the filename with whichever file you want to run.

---

## Troubleshooting

**"dart: command not found"**  
Dart is not installed or not in your PATH. Repeat Step 1.

**"Could not find package…"**  
You skipped Step 3 or ran it in the wrong folder. Make sure your terminal is inside the `eba_randomisation` folder and run `dart pub get` again.

**Tests fail with a database error on Linux**  
You may be missing the `sqlite3` native library. Run:
```
sudo apt-get install libsqlite3-dev
```
Then run `dart test` again.

**Tests fail on Windows with a DLL error**  
Download `sqlite3.dll` from https://sqlite.org/download.html (under "Precompiled Binaries for Windows") and place it in the same folder as the `dart.exe` binary (usually `C:\dart-sdk\bin\`).

---

## Reporting results

After running `dart test`, please send the team:
1. The full terminal output (copy-paste or screenshot).
2. Your operating system (macOS / Windows / Linux) and version.
3. The output of `dart --version`.
