module main

import ncurses
import os

fn main() {
	mut session := ncurses.create_session(use_keyboard: true) or {
		panic(err)
	}

	mut x := i16(0)
	mut y := i16(0)

	mut str := []byte{}
	mut edit_mode := true
	mut cmd_i := 0
	mut cmd := []byte{}
	mut error_printed := false

	mut log := []string{}

	for {
		char := session.get_char() or { break }

		if char == 10 && !edit_mode {
			session.clear_line(i16(session.terminal_size.rows - 1))
			session.refresh()
			if cmd.len == 0 {
				// handle empty commands
				continue
			}

			cmd_i = 0
			args := string(cmd).fields()
			cmd = []byte{}
			mut quit := false 
			mut error := ''
			for i := 0; i < args.len; i++ {
				arg := args[i]
				match arg {
					'w', 'write' {
						session.move(x, y)
						edit_mode = true
						continue
					}
					's', 'save' {
						file := args[i+1]
						i++
						os.write_file(file, str.bytestr()) or {
							error = err.msg
							continue
						}
					}
					'c', 'close', 'q', 'quit' {
						quit = true
					}
					else {
						error = 'Unknown command `${arg}`'
					}
				}
			}
			if error != '' {
				session.move(0, i16(session.terminal_size.rows - 1))
				session.write_string(0, i16(session.terminal_size.rows - 1), error)
				error_printed = true
				session.refresh()
				continue		
			}
			if quit {
				break
			}
		}

		if char == 27 && edit_mode {
			edit_mode = false
			session.write_string(0, i16(session.terminal_size.rows - 1), ' '.repeat(session.terminal_size.cols - 1))
			session.move(0, i16(session.terminal_size.rows - 1))
			cmd_i = 0
			cmd = []byte{}
			session.refresh()
			continue
		}

		if char == 7 {
			// remove last char
			if str.len > 0 && edit_mode {
				c := str.last()
				str = str[..str.len - 1]
				session.write_string(x - 1, y, ' ')
				session.refresh()
				x--
				if c == `\n` {
					y--

					// calc x
					x = i16(str.bytestr().split_into_lines().last().len)
				}
				session.move(x, y)
				session.refresh()
			} else if cmd.len > 0 && !edit_mode {
				cmd = cmd[..cmd.len - 1]
				session.write_string(i16(cmd_i - 1), i16(session.terminal_size.rows - 1), ' ')
				session.refresh()
				cmd_i--
				session.move(i16(cmd_i), i16(session.terminal_size.rows - 1))
				session.refresh()
			}
			continue
		}

		if (char < 33 || char == 127) && char != `\n` && char != ` ` {
			continue
		}

		if edit_mode {
			s := char.ascii_str()
			session.write_string(x, y, s)
			str << char
			x++
			if char == `\n` {
				y++
				x = 0
			}
		} else {
			if error_printed {
				error_printed = false
				session.clear_line(i16(session.terminal_size.rows - 1))
				session.refresh()
			}
			s := char.ascii_str()
			session.write_string(i16(cmd_i), i16(session.terminal_size.rows - 1), s)
			cmd << char
			cmd_i++
		}

		session.refresh()
	}

	session.close_session()
	for l in log {
		eprintln(l)
	}
}