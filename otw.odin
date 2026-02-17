package main

import "core:encoding/json"
import "core:encoding/uuid"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"

Task :: struct {
	uuid:        string,
	description: string,
	status:      Status,
	priority:    Priority,
	due:         time.Time,
	tags:        []string,
	project:     string,
	created_at:  time.Time,
	updated_at:  time.Time,
}

Status :: enum {
	Open,
	Done,
}

Priority :: enum {
	H,
	M,
	L,
}

task_create :: proc(
	description: string,
	due: time.Time = time.Time{},
	tags: []string = nil,
	project: string = "",
) -> Task {
	return Task {
		uuid = new_uuid(),
		description = description,
		status = Status.Open,
		priority = Priority.M,
		due = due,
		tags = tags,
		project = project,
		created_at = time.now(),
		updated_at = time.now(),
	}
}

task_save :: proc(path: string, t: Task) -> bool {
	data, jerr := json.marshal(t)
	if jerr != nil {
		fmt.println("json error:", jerr)
		return false
	}
	defer delete(data)

	ok := os.write_entire_file(path, data)
	if !ok {
		fmt.println("file write failed:", path)
		return false
	}
	return true
}

new_uuid :: proc() -> string {
	return uuid.to_string(uuid.generate_v7_basic(time.now()))
}

args_parse :: proc(args: []string) -> Task {
	args_description: [dynamic]string
	defer delete(args_description)
	args_tags: [dynamic]string

	for arg in args {
		if len(arg) > 0 && arg[0] == u8('+') {
			if len(arg) > 1 {
				append(&args_tags, arg[1:])
			}
		} else {
			append(&args_description, arg)
		}
	}
	task_description := strings.join(args_description[:], " ")

	return task_create(task_description, tags = args_tags[:])
}


main :: proc() {
	if len(os.args) > 1 {
		if os.args[1] == "add" {
			t := args_parse(os.args[2:])
			task_save("task.json", t)
		} else {
			fmt.println("unknown command:", os.args[1])
		}
	}
}
