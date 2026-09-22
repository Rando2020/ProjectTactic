extends RefCounted

const RIGHT_PANEL_WIDE_WIDTH := 360.0
const RIGHT_PANEL_COMPACT_WIDTH := 320.0
const RIGHT_PANEL_BREAKPOINT := 1600.0
const RIGHT_PANEL_MARGIN := 12.0
const RIGHT_PANEL_TOP := 8.0
const RIGHT_PANEL_MAX_HEIGHT := 704.0


static func right_sidebar_rect(viewport_size: Vector2) -> Rect2:
	var panel_width: float = RIGHT_PANEL_COMPACT_WIDTH if viewport_size.x < RIGHT_PANEL_BREAKPOINT else RIGHT_PANEL_WIDE_WIDTH
	var panel_height: float = minf(RIGHT_PANEL_MAX_HEIGHT, maxf(0.0, viewport_size.y - RIGHT_PANEL_TOP * 2.0))
	var panel_x: float = maxf(RIGHT_PANEL_MARGIN, viewport_size.x - panel_width - RIGHT_PANEL_MARGIN)
	return Rect2(panel_x, RIGHT_PANEL_TOP, panel_width, panel_height)
