import os
import shutil
from pathlib import Path
from datetime import datetime
from tkinter import (
    Tk, Label, Entry, Radiobutton, IntVar,
    Checkbutton, BooleanVar, StringVar, ttk, Frame, Button
)
from tkinter import filedialog
from PIL import Image, ExifTags
import sys
import webbrowser

JPG_EXTS = {'.jpg', '.jpeg', '.png', 'hiff'}
RAW_EXTS = {
    '.cr2', '.cr3',  # Canon
    '.nef', '.nrw',  # Nikon
    '.arw', '.srf', '.sr2',  # Sony
    '.raf',          # Fujifilm
    '.dng',          # Leica, Pentax
    '.rw2',          # Panasonic
    '.orf',          # Olympus
    '.pef',          # Pentax
    '.x3f',          # Sigma
    '.3fr', '.fff'   # Hasselblad
}

ALL_EXTS = JPG_EXTS.union(RAW_EXTS)

MODE_KEEP_NAME = 1
MODE_NUMBERED = 2
MODE_DATE_BASED = 3

def get_date_taken(file_path):
    try:
        img = Image.open(file_path)
        exif = img._getexif()
        if not exif:
            return None
        for tag, val in exif.items():
            if ExifTags.TAGS.get(tag) == 'DateTimeOriginal':
                return datetime.strptime(val, '%Y:%m:%d %H:%M:%S')
    except:
        pass
    return None

def generate_numbered_filename(dest_folder, ext, base_name=''):
    index = 1
    while True:
        name = f"{base_name}_{index}" if base_name else f"{index}"
        candidate = dest_folder / f"{name}{ext}"
        if not candidate.exists():
            return candidate
        index += 1

def generate_date_based_filename(dest_folder, ext, base_name, date_taken):
    date_str = date_taken.strftime('%Y%m%d')
    index = 1
    while True:
        name = f"{base_name}_{date_str}_{index}" if base_name else f"{date_str}_{index}"
        candidate = dest_folder / f"{name}{ext}"
        if not candidate.exists():
            return candidate
        index += 1

def move_file(src, dest_folder, mode, base_name='', overwrite=False, date_taken=None):
    dest_folder.mkdir(parents=True, exist_ok=True)

    ext = src.suffix.lower()
    if mode == MODE_NUMBERED:
        dest_path = generate_numbered_filename(dest_folder, ext, base_name)
    elif mode == MODE_DATE_BASED and date_taken:
        dest_path = generate_date_based_filename(dest_folder, ext, base_name, date_taken)
    else:
        dest_path = dest_folder / src.name

    if dest_path.exists():
        if overwrite:
            dest_path.unlink()
        else:
            print(f"⚠️ 건너뜀: {src.name}")
            return

    shutil.move(str(src), str(dest_path))

def organize_photos(folder_path, mode, base_name, overwrite, process_jpg, process_raw, date_format, by_extension, progress_callback=None):
    folder = Path(folder_path.strip('{}'))
    if not folder.is_dir():
        return

    files = list(folder.rglob('*'))
    total_files = len(files)
    processed = 0

    for file in files:
        if not file.is_file():
            continue

        ext = file.suffix.lower()
        is_jpg = ext in JPG_EXTS
        is_raw = ext in RAW_EXTS

        if by_extension:
            dest_folder = folder / ext[1:].upper()
            date_taken = get_date_taken(file) or datetime.fromtimestamp(file.stat().st_mtime)
        else:
            if not (is_jpg or is_raw):
                continue

            should_organize = (
                (is_jpg and process_jpg) or
                (is_raw and process_raw) or
                (mode in (MODE_NUMBERED, MODE_DATE_BASED) or date_format != 0)
            )
            if not should_organize:
                continue

            date_taken = get_date_taken(file) or datetime.fromtimestamp(file.stat().st_mtime)

            if is_jpg:
                category = 'JPG' if process_jpg else ''
            elif is_raw:
                category = 'RAW' if process_raw else ''
            else:
                category = ''

            if date_format == 1:
                subfolder = Path(date_taken.strftime('%Y%m'))
            elif date_format == 2:
                subfolder = Path(date_taken.strftime('%Y')) / date_taken.strftime('%m')
            elif date_format == 3:
                subfolder = Path(date_taken.strftime('%Y-%m-%d'))
            else:
                subfolder = Path()

            dest_folder = folder
            if category:
                dest_folder = dest_folder / category
            dest_folder = dest_folder / subfolder

        move_file(file, dest_folder, mode, base_name, overwrite, date_taken)

        processed += 1
        if progress_callback:
            progress_callback(int(processed / total_files * 100))

def create_ui():
    root = Tk()
    root.title("📷 Image Organizer")
    root.geometry("480x650")

    try:
        if sys.platform == 'darwin':
            icon_path = os.path.join(os.path.dirname(__file__), 'icon.icns')
            if not os.path.exists(icon_path):
                icon_path = os.path.join(os.path.dirname(__file__), 'icon.ico')
        else:
            icon_path = os.path.join(os.path.dirname(__file__), 'icon.ico')

        if os.path.exists(icon_path):
            root.iconbitmap(icon_path)
    except:
        pass

    # Label(root, text="🗂️Image Organizer", font=("맑은 고딕", 14, "bold")).pack(pady=(10, 5))

    mode_var = IntVar(value=MODE_KEEP_NAME)
    name_var = StringVar()
    explanation_var = StringVar()

    def on_mode_change():
        if mode_var.get() == MODE_NUMBERED:
            name_entry.config(state="normal")
            explanation_label.config(text=(
                "예 : 이미지 → 이미지_1.jpg ..."
            ))
        elif mode_var.get() == MODE_DATE_BASED:
            name_entry.config(state="normal")
            explanation_label.config(text=(
                "예 : 이미지 → 이미지_20250625_1.jpg ..."
            ))
        else:
            name_entry.config(state="disabled")
            explanation_label.config(text="")

    Label(root, text="📂 파일명 선택", font=("맑은 고딕", 10, "bold")).pack(pady=(10, 5))

    Radiobutton(root, text="기존 파일명 유지", variable=mode_var, value=MODE_KEEP_NAME, command=on_mode_change).pack()
    Radiobutton(root, text="번호로 파일명 부여", variable=mode_var, value=MODE_NUMBERED, command=on_mode_change).pack()
    Radiobutton(root, text="날짜로 파일명 부여", variable=mode_var, value=MODE_DATE_BASED, command=on_mode_change).pack()

    name_entry = Entry(root, textvariable=name_var, state="disabled")
    name_entry.pack(pady=(5, 0))
    explanation_label = Label(root, text="", font=("맑은 고딕", 9), fg="gray")
    explanation_label.pack()

    Label(root, text="📂 폴더 포맷 선택", font=("맑은 고딕", 10, "bold")).pack(pady=(10, 5))
    
    jpg_var = BooleanVar(value=False)
    raw_var = BooleanVar(value=False)
    by_ext_var = BooleanVar(value=True)

    jpg_cb = Checkbutton(root, text="JPG 분류", variable=jpg_var, state="disabled")
    raw_cb = Checkbutton(root, text="RAW 분류", variable=raw_var, state="disabled")
    jpg_cb.pack()
    raw_cb.pack()

    def on_by_ext_toggle():
        if by_ext_var.get():
            jpg_var.set(False)
            raw_var.set(False)
            jpg_cb.config(state="disabled")
            raw_cb.config(state="disabled")
        else:
            jpg_cb.config(state="normal")
            raw_cb.config(state="normal")

    Checkbutton(root, text="확장자별 폴더로 정리 (.JPG, .CR3 등)", variable=by_ext_var, command=on_by_ext_toggle).pack(pady=(10, 0))

    overwrite_var = BooleanVar(value=False)
    Checkbutton(root, text="동일 파일명 덮어쓰기 허용", variable=overwrite_var).pack(pady=5)

    
    Label(root, text="📅 날짜 폴더 포맷 선택").pack(pady=(10, 0))

    date_format_var = IntVar(value=0)
    Radiobutton(root, text="YYYYMM", variable=date_format_var, value=1).pack()
    Radiobutton(root, text="YYYY/MM", variable=date_format_var, value=2).pack()
    Radiobutton(root, text="YYYY-MM-DD", variable=date_format_var, value=3).pack()
    Radiobutton(root, text="날짜 포맷 선택하지 않기", variable=date_format_var, value=0).pack()

    drop_frame = Frame(root, width=420, height=120, bg="#e0e0e0", relief="ridge", bd=2)
    drop_frame.pack(pady=5)
    drop_frame.pack_propagate(False)

    drop_label = Label(drop_frame, text="", bg="#e0e0e0", font=("맑은 고딕", 9), fg="gray")
    drop_label.place(relx=0.5, rely=0.75, anchor="center")

    progress = ttk.Progressbar(root, orient='horizontal', length=400, mode='determinate')
    progress.pack(pady=15)

    instagram_frame = Frame(root)
    instagram_frame.pack(pady=(0, 3), anchor='se', padx=10)
    Label(instagram_frame, text="Instagram: ", font=("맑은 고딕", 8), fg="gray").pack(side='left')
    instagram_link = Label(instagram_frame, text="@duaghwns", font=("맑은 고딕", 8), fg="#0066cc", cursor="hand2")
    instagram_link.pack(side='left')

    def open_instagram(event):
        webbrowser.open("https://www.instagram.com/duaghwns/")

    instagram_link.bind("<Button-1>", open_instagram)
    instagram_link.bind("<Enter>", lambda e: instagram_link.config(fg="#0044aa", font=("맑은 고딕", 8, "underline")))
    instagram_link.bind("<Leave>", lambda e: instagram_link.config(fg="#0066cc", font=("맑은 고딕", 8)))

    def process_folder(folder_path):
        if not folder_path or not os.path.exists(folder_path):
            drop_label.config(text="⚠️ 유효하지 않은 경로입니다.")
            return

        drop_label.config(text="📂 정리 중입니다...")
        root.update_idletasks()

        mode = mode_var.get()
        base_name = name_var.get().strip()
        if not base_name:
            base_name = ''

        overwrite = overwrite_var.get()
        process_jpg = jpg_var.get()
        process_raw = raw_var.get()
        date_format = date_format_var.get()
        by_extension = by_ext_var.get()

        progress['value'] = 0
        def update_progress(value):
            progress['value'] = value
            root.update_idletasks()

        organize_photos(folder_path, mode, base_name, overwrite, process_jpg, process_raw, date_format, by_extension, update_progress)
        drop_label.config(text="✅ 정리 완료! 다시 선택 가능")

    def select_folder():
        folder_path = filedialog.askdirectory(title="정리할 폴더를 선택하세요")
        if folder_path:
            process_folder(folder_path)

    select_button = Button(drop_frame, text="📂 폴더 선택", command=select_folder, font=("맑은 고딕", 11, "bold"), bg="#4CAF50", fg="white", padx=20, pady=10)
    select_button.place(relx=0.5, rely=0.5, anchor="center")

    root.mainloop()

if __name__ == "__main__":

    create_ui()
