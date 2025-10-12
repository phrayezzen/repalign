import { Controller, Get, Post, Delete, Param, Body, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { EventService } from './events.service';
import { FeedItemDto } from '../feed/dto/feed-item.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('congress')
@Controller('congress')
export class CongressController {
  constructor(
    private readonly eventService: EventService,
  ) {}

  @Get('events/:id')
  @ApiOperation({ summary: 'Get event by ID' })
  @ApiResponse({ status: 200, description: 'Event details', type: FeedItemDto })
  async getEvent(@Param('id') id: string): Promise<FeedItemDto> {
    return this.eventService.getEventById(id);
  }

  @Post('events/:id/rsvp')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'RSVP to an event' })
  @ApiResponse({ status: 201, description: 'RSVP successful' })
  async rsvpToEvent(@Param('id') eventId: string, @Request() req: any) {
    return this.eventService.rsvpToEvent(eventId, req.user.id);
  }

  @Delete('events/:id/rsvp')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Cancel RSVP to an event' })
  @ApiResponse({ status: 200, description: 'RSVP cancelled' })
  async cancelRsvp(@Param('id') eventId: string, @Request() req: any) {
    return this.eventService.cancelRsvp(eventId, req.user.id);
  }

  @Post('events')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create a new event' })
  @ApiResponse({ status: 201, description: 'Event created', type: FeedItemDto })
  async createEvent(@Body() createEventDto: any, @Request() req: any): Promise<FeedItemDto> {
    return this.eventService.createEvent(createEventDto, req.user.id);
  }
}