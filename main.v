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
  projects []Root_project
}

fn main() {
  println("Checking for updates...")

  // Load local pkglist
  mut pkglist_raw := os.read_file("pkglist.json") or { eprintln("Failed to read pkglist.json: $err"); return }
  mut pkglist_json := json.decode(Pkglist, pkglist_raw) or { eprintln("Failed to decode pkglist.json: $err"); return }

  // Load root pkglist
  pkglist_root_raw := os.read_file("pkglist_root.json") or { eprintln("Failed to read pkglist_root.json: $err"); return }
  pkglist_root_json := json.decode(Root_pkglist, pkglist_root_raw) or { eprintln("Failed to decode pkglist_root.json: $err"); return }

  // Map root URLs by project name
  mut root_url_map := map[string]string{}
  for project in pkglist_root_json.projects {
    root_url_map[project.name] = project.url
  }

  // Update only the version in local pkglist
  for mut project in pkglist_json.projects {
    if root_url := root_url_map[project.name] {
      latest_tag := get_latest_tag(root_url)
      if latest_tag != "" {
        project.version = latest_tag  // update version only
        println("Updated $project.name to version $latest_tag")
      } else {
        println("No tags found for $project.name")
      }
    } else {
      println("No root URL found for $project.name")
    }
  }

  // Write updated pkglist back to disk
  updated_json := json.encode_pretty(pkglist_json)
  os.write_file("pkglist.json", updated_json) or { eprintln("Failed to write updated pkglist.json: $err") }
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
