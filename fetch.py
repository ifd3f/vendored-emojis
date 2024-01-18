#!/usr/bin/env python3

import shutil
import base64
import zipfile
import hashlib
import json
import traceback

from pathlib import Path

import requests


def main():
    packzips_dir = Path('download')
    packs_dir = Path('packs')

    packzips_dir.mkdir(parents=True, exist_ok=True)

    with open('sources.json') as f:
        targets = json.load(f)
    
    lockfile = {}

    for k, spec in targets.items():
        url = spec_to_url(spec)
        print(f"Fetching {k} at {url}")
        try:
            zip_path = packzips_dir / f'{k}.zip'
            pack_path = packs_dir / k
            sha = download_file(url, zip_path)
            lockfile[k] = {
                'url': url,
                'zip_path': str(zip_path),
                'pack_path': str(pack_path),
                'hash': 'sha256-' + base64.b64encode(sha).decode('utf-8'),
            }
            with zipfile.ZipFile(zip_path, 'r') as zip_ref:
                shutil.rmtree(pack_path, ignore_errors=True)
                pack_path.mkdir(parents=True, exist_ok=True)
                print(pack_path)
                zip_ref.extractall(pack_path)

        except KeyboardInterrupt:
            return

        except:
            print(f"Error fetching {k}")
            traceback.print_exc()
    
    with open('sources.lock', 'w') as f:
        json.dump(lockfile, f, indent=4)

    to_delete = []
    for file in packs_dir.iterdir():
        if file.name not in lockfile:
            to_delete.append(file)

    if to_delete:
        print()
        print("Deleting packs:")
        for f in to_delete:
            print(f'  - {f}')
        
        for f in to_delete:
            f.unlink()


def spec_to_url(spec):
    source, key = spec.split(':')
    match source:
        case 'pleroma':
            return f"https://git.pleroma.social/pleroma/emoji-index/-/raw/master/packs/{key}.zip";
        case 'absturztaube':
            return f"https://emoji-repo.absturztau.be/repo/{key}.zip";
        case 'volpeon':
            return f"https://volpeon.ink/emojis/{key}/{key}.zip";
    return spec


def download_file(url: str, dest: Path) -> bytes:
    with requests.get(url, stream=True) as r:
        r.raise_for_status()
        with dest.open('wb') as f:
            hash = hashlib.sha256()
            for chunk in r.iter_content(chunk_size=8192): 
                hash.update(chunk)
                f.write(chunk)
            return hash.digest()


if __name__ == '__main__':
    main()
