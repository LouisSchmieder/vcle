module terminal

#include <sys/ioctl.h>

fn C.ioctl(fd i16, request u32, data voidptr) int

struct C.winsize {
	ws_row u16
	ws_col u16
}

pub struct TerminalSize {
pub:
	rows u16
	cols u16
}

pub fn get_terminal_size() TerminalSize {
	mut winsize := C.winsize{}
	C.ioctl(0, 0x5413, &winsize)

	return TerminalSize{
		rows: winsize.ws_row
		cols: winsize.ws_col
	}
}