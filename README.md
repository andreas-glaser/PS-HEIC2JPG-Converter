# PS-HEIC2JPG-Converter

A PowerShell script to convert HEIC files to JPEG using ImageMagick. This tool is designed to be simple, efficient, and user-friendly, offering features such as unique filename generation, detailed conversion statistics (file sizes, conversion time), a progress bar, and configurable options for logging and moving original files to the Recycle Bin.

## Features

- **HEIC to JPEG Conversion:**  
  Converts HEIC images to JPEG format using ImageMagick.

- **Unique Filename Generation:**  
  Automatically appends a numeric suffix if an output file with the intended name already exists, similar to Windows file naming.

- **Detailed Conversion Metrics:**  
  Displays the original and new file sizes (in MB) with percentage change (indicating if the size increased or reduced), the conversion time for each file, and the overall runtime.

- **Progress Feedback:**  
  Shows a progress bar that updates as files are processed.

- **Configurable Options:**  
  - **Recursion:** Process files only in the specified directory or include subdirectories using the `-Recurse` switch.
  - **Move to Trash:** By default, the original HEIC files are moved to the Recycle Bin after conversion. Use `-MoveToTrash:$false` to keep them in place.
  - **Logging:** Optionally generate log files (`conversion.log` and `conversion_errors.log`) in the script’s directory with the `-EnableLogging` switch.

- **Parameter Summary:**  
  A neatly formatted table is displayed before conversion, allowing you to review your settings.

## Dependencies

- **PowerShell 7 or later**  
  This script uses features available in PowerShell 7+.

- **ImageMagick**  
  The script relies on the `magick` command. Ensure ImageMagick is installed and that the `magick` command is available in your system’s PATH.

## Installation

1. **Clone or Download the Repository:**  
   ```bash
   git clone https://github.com/andreas-glaser/PS-HEIC2JPG-Converter.git
   ```
2. **Ensure Dependencies Are Met:**  
   - Install [PowerShell 7+](https://github.com/PowerShell/PowerShell#get-powershell).
   - Install [ImageMagick](https://imagemagick.org/script/download.php) and make sure the `magick` command is in your PATH.
3. **Navigate to the Repository Folder:**  
   Open PowerShell and change to the repository directory.

## Usage

Run the script using the following syntax:

```powershell
.\heic2jpg.ps1 -TargetDirectory "Path\To\Your\Directory" [-Recurse] [-MoveToTrash] [-EnableLogging] [other parameters]
```

### Examples

- **Convert files in a directory (non-recursive, with default move to trash):**
  ```powershell
  .\heic2jpg.ps1 -TargetDirectory "C:\Images\HEIC"
  ```

- **Convert files in a directory without moving originals:**
  ```powershell
  .\heic2jpg.ps1 -TargetDirectory "C:\Images\HEIC" -MoveToTrash:$false
  ```

- **Convert files recursively with logging enabled:**
  ```powershell
  .\heic2jpg.ps1 -TargetDirectory "C:\Images\HEIC" -Recurse -EnableLogging
  ```

## Parameters

| Parameter          | Type    | Default      | Description                                                                                                 |
|--------------------|---------|--------------|-------------------------------------------------------------------------------------------------------------|
| `-TargetDirectory` | String  | *(Required)* | The directory containing HEIC files to convert.                                                           |
| `-Recurse`         | Switch  | Off          | Process files in subdirectories.                                                                          |
| `-MoveToTrash`     | Boolean | `$true`      | Move the original HEIC file to the Recycle Bin after conversion. Use `-MoveToTrash:$false` to keep the file.  |
| `-EnableLogging`   | Switch  | Off          | If specified, enable logging. Creates `conversion.log` and `conversion_errors.log` in the script's directory. |
| `-InputExtension`  | String  | `"*.heic"`   | File extension filter for input files.                                                                    |
| `-OutputExtension` | String  | `".jpg"`     | Extension for output files.                                                                                 |
| `-Quality`         | Int     | `95`         | JPEG quality for conversion (1 = lowest, 100 = highest).                                                  |

## How It Works

1. **File Discovery:**  
   The script scans the target directory (and subdirectories if `-Recurse` is provided) for files matching the input extension.

2. **Parameter Summary & File Listing:**  
   It displays a neatly formatted table of conversion parameters and lists the files to be converted (up to 10 files).

3. **Conversion Process:**  
   For each file, the script:
   - Generates a unique output filename if needed.
   - Calls ImageMagick (`magick`) to convert the file to JPEG using the specified quality.
   - Logs output and errors if logging is enabled.
   - Calculates and displays the original file size, new file size, and the percentage change (indicating whether the size increased or reduced).
   - Reports the conversion time for each file.

4. **Overall Metrics:**  
   Once all files are processed, the script displays the total runtime.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
