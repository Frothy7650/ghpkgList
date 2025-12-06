import json
import os

struct Project {
  name    string
  mut: version string
  url     string
}

struct Pkglist {
  projects []Project
}

struct Root_project {
  name    string
  mut: version string
  url     string
}

struct Root_pkglist {
  projects []Project
}

fn main() {
  println("Checking for updates...")

  // Load pkglist
  mut pkglist_raw := os.read_file("pkglist.json") or { eprintln("Failed to read pkglist.json: $err") return }
  mut pkglist_json := json.decode(Pkglist, pkglist_raw) or { eprintln("Failed to decode pkglist.json: $err") return }

  // Load pkglist_root
  pkglist_root_raw := os.read_file("pkglist_root.json") or { eprintln("Failed to read pkglist_root.json: $err") return }
  pkglist_root_json := json.decode(Root_pkglist, pkglist_root_raw) or { eprintln("Failed to decode pkglist_root.json: $err") return }

  // Create a map from project name → URL
  mut url_map := map[string]string{}
  for root_project in pkglist_root_json.projects {
    url_map[root_project.name] = root_project.url
  }

  // Iterate through projects
  for mut project in pkglist_json.projects {
    if project.name in url_map {
      project.url = url_map[project.name] // get URL from root pkglist
      latest := get_latest_tag(project.url)
      if latest != project.version {
        project.version = latest
        println("${project.name} updated to ${latest}")
      }
    } else {
      eprintln("No URL found for project: ${project.name}")
    }
  }

  // Write back
  pkglist_raw = json.encode_pretty(pkglist_json)
  os.write_file("pkglist.json", pkglist_raw) or { eprintln("Failed to write pkglist.json: $err") return }
}

fn get_latest_tag(url string) string {
  result := os.execute('git ls-remote --refs --tags ${url}')
  if result.exit_code != 0 {
    eprintln("Failed to fetch tags from ${url}")
    return ""
  }
  lines := result.output.trim_space().split("\n")
  if lines.len == 0 {
    return ""
  }
  latest_tag_line := lines.last()
  // git output: <hash>\trefs/tags/<tagname>
  parts := latest_tag_line.split("\t")
  if parts.len < 2 {
    return ""
  }
  tag := parts[1].all_after("refs/tags/")
  return tag
}
