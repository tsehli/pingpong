const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});
const assert = std.debug.assert;

const WINDOW_WIDTH = 800;
const WINDOW_HEIGHT = 600;
const FPS = 60;
const DELTA_TIME_SEC: f32 = 1.0 / @as(f32, FPS);
const BALL_SIZE = 15;
const BALL_SPEED: f32 = 400;
const BAR_LEN: f32 = 100;
const BAR_THICKNESS: f32 = 10;
const BAR_Y: f32 = WINDOW_HEIGHT - BAR_THICKNESS - 100;
const BAR_SPEED: f32 = BALL_SPEED;

const Point = struct {
    x: f32,
    y: f32,
};

pub fn main() !void {
    if (c.SDL_Init(c.SDL_INIT_VIDEO) < 0) {
        c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    defer c.SDL_Quit();

    const screen = c.SDL_CreateWindow("PingPong", c.SDL_WINDOWPOS_UNDEFINED, c.SDL_WINDOWPOS_UNDEFINED, WINDOW_WIDTH, WINDOW_HEIGHT, c.SDL_WINDOW_OPENGL) orelse {
        c.SDL_Log("Unable to create window: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyWindow(screen);

    const renderer = c.SDL_CreateRenderer(screen, -1, c.SDL_RENDERER_ACCELERATED) orelse {
        c.SDL_Log("Unable to create renderer: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyRenderer(renderer);

    const keyboard = c.SDL_GetKeyboardState(null);

    var quit = false;
    var ball_pos = Point{ .x = 100, .y = 100 };
    var ball_vel = Point{ .x = 1, .y = 1 };
    var bar_x: f32 = 0;
    var bar_dx: f32 = 0;
    var pause = false;

    while (!quit) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_QUIT => {
                    quit = true;
                },
                c.SDL_KEYDOWN => {
                    // c.SDL_Log("%d\n", event.key.keysym.sym);
                    switch (event.key.keysym.sym) {
                        c.SDLK_LEFT => {
                            bar_x -= 10;
                        },
                        c.SDLK_RIGHT => {
                            bar_x += 10;
                        },
                        c.SDLK_SPACE => {
                            pause = !pause;
                        },
                        else => {},
                    }
                },

                else => {},
            }
        }

        if (pause) {
            c.SDL_Delay(1000 / FPS);
            continue;
        }

        bar_dx = 0;
        if (keyboard[c.SDL_SCANCODE_LEFT] != 0) {
            bar_dx += -1;
        }
        if (keyboard[c.SDL_SCANCODE_RIGHT] != 0) {
            bar_dx += 1;
        }
        // c.SDL_Log("%f\n", bar_dx);

        _ = c.SDL_SetRenderDrawColor(renderer, 0x18, 0x18, 0x18, 0xFF);
        _ = c.SDL_RenderClear(renderer);

        bar_x += bar_dx * BAR_SPEED * DELTA_TIME_SEC;

        if (bar_x + BAR_LEN > WINDOW_WIDTH) {
            bar_x = WINDOW_WIDTH - BAR_LEN;
        }

        if (bar_x < 0) {
            bar_x = 0;
        }
        const bar_y: f32 = BAR_Y - BAR_THICKNESS / 2;
        const bar_rect = c.SDL_Rect{
            .x = @intFromFloat(bar_x),
            .y = BAR_Y - BAR_THICKNESS / 2,
            .w = BAR_LEN,
            .h = BAR_THICKNESS,
        };

        var ball_next_pos = Point{
            .x = ball_pos.x + ball_vel.x * BALL_SPEED * DELTA_TIME_SEC,
            .y = ball_pos.y + ball_vel.y * BALL_SPEED * DELTA_TIME_SEC,
        };

        // intersection with bar (approximate)
        if (ball_next_pos.x + BALL_SIZE >= bar_x and ball_next_pos.x - BALL_SIZE <= bar_x + BAR_LEN) {
            if ((ball_pos.y < bar_y and ball_pos.y + BALL_SIZE >= bar_y) or (ball_pos.y > bar_y and ball_pos.y - BALL_SIZE <= bar_y)) {
                ball_vel.y *= -1;
                ball_next_pos.y = ball_pos.y + ball_vel.y * BALL_SPEED * DELTA_TIME_SEC;
            }
        }

        if (ball_next_pos.x < BALL_SIZE or ball_next_pos.x + BALL_SIZE > WINDOW_WIDTH) {
            ball_vel.x *= -1;
            ball_next_pos.x = ball_pos.x + ball_vel.x * BALL_SPEED * DELTA_TIME_SEC;
        }
        if (ball_next_pos.y < BALL_SIZE or ball_next_pos.y + BALL_SIZE > WINDOW_HEIGHT) {
            ball_vel.y *= -1;
            ball_next_pos.y = ball_pos.y + ball_vel.y * BALL_SPEED * DELTA_TIME_SEC;
        }

        ball_pos = ball_next_pos;

        // draw the ball
        _ = c.SDL_SetRenderDrawColor(renderer, 0xFF, 0xFF, 0xFF, 0xFF);
        _ = SDL_RenderFillCircle(renderer, @intFromFloat(ball_pos.x), @intFromFloat(ball_pos.y), BALL_SIZE);

        // Draw the bar
        _ = c.SDL_SetRenderDrawColor(renderer, 0xFF, 0x00, 0x00, 0xFF);
        _ = c.SDL_RenderFillRect(renderer, &bar_rect);

        _ = c.SDL_RenderPresent(renderer);

        c.SDL_Delay(1000 / FPS);
    }
}

fn SDL_RenderDrawCircle(renderer: *c.SDL_Renderer, x: i32, y: i32, radius: i32) i32 {
    var offsetx: i32 = 0;
    var offsety: i32 = radius;
    var d: i32 = radius - 1;
    var status: i32 = 0;

    while (offsety >= offsetx) {
        status += c.SDL_RenderDrawPoint(renderer, x + offsetx, y + offsety);
        status += c.SSDL_RenderDrawPoint(renderer, x + offsety, y + offsetx);
        status += c.SSDL_RenderDrawPoint(renderer, x - offsetx, y + offsety);
        status += c.SSDL_RenderDrawPoint(renderer, x - offsety, y + offsetx);
        status += c.SSDL_RenderDrawPoint(renderer, x + offsetx, y - offsety);
        status += c.SSDL_RenderDrawPoint(renderer, x + offsety, y - offsetx);
        status += c.SSDL_RenderDrawPoint(renderer, x - offsetx, y - offsety);
        status += c.SSDL_RenderDrawPoint(renderer, x - offsety, y - offsetx);

        if (status < 0) {
            status = -1;
            break;
        }

        if (d >= 2 * offsetx) {
            d -= 2 * offsetx + 1;
            offsetx += 1;
        } else if (d < 2 * (radius - offsety)) {
            d += 2 * offsety - 1;
            offsety -= 1;
        } else {
            d += 2 * (offsety - offsetx - 1);
            offsety -= 1;
            offsetx += 1;
        }
    }

    return status;
}

fn SDL_RenderFillCircle(renderer: *c.SDL_Renderer, x: i32, y: i32, radius: i32) i32 {
    var offsetx: i32 = 0;
    var offsety: i32 = radius;
    var d: i32 = radius - 1;
    var status: i32 = 0;

    while (offsety >= offsetx) {
        status += c.SDL_RenderDrawLine(renderer, x - offsety, y + offsetx, x + offsety, y + offsetx);
        status += c.SDL_RenderDrawLine(renderer, x - offsetx, y + offsety, x + offsetx, y + offsety);
        status += c.SDL_RenderDrawLine(renderer, x - offsetx, y - offsety, x + offsetx, y - offsety);
        status += c.SDL_RenderDrawLine(renderer, x - offsety, y - offsetx, x + offsety, y - offsetx);

        if (status < 0) {
            status = -1;
            break;
        }

        if (d >= 2 * offsetx) {
            d -= 2 * offsetx + 1;
            offsetx += 1;
        } else if (d < 2 * (radius - offsety)) {
            d += 2 * offsety - 1;
            offsety -= 1;
        } else {
            d += 2 * (offsety - offsetx - 1);
            offsety -= 1;
            offsetx += 1;
        }
    }

    return status;
}
