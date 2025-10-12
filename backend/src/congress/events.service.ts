import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Event } from './entities/event.entity';
import { EventParticipant, ParticipantStatus } from './entities/event-participant.entity';
import { FeedItemDto, FeedItemType } from '../feed/dto/feed-item.dto';
import { User } from '../users/entities/user.entity';

@Injectable()
export class EventService {
  constructor(
    @InjectRepository(Event)
    private eventRepository: Repository<Event>,
    @InjectRepository(EventParticipant)
    private participantRepository: Repository<EventParticipant>,
    @InjectRepository(User)
    private userRepository: Repository<User>,
  ) {}

  async getEventById(id: string): Promise<FeedItemDto> {
    const event = await this.eventRepository.findOne({
      where: { id },
      relations: ['creator'],
    });

    if (!event) {
      throw new NotFoundException('Event not found');
    }

    return this.mapEventToFeedItem(event);
  }

  async rsvpToEvent(eventId: string, userId: string) {
    const event = await this.eventRepository.findOne({ where: { id: eventId } });
    if (!event) {
      throw new NotFoundException('Event not found');
    }

    const existingParticipant = await this.participantRepository.findOne({
      where: { eventId, userId },
    });

    if (existingParticipant) {
      existingParticipant.markAsAttending();
      await this.participantRepository.save(existingParticipant);
    } else {
      const participant = this.participantRepository.create({
        eventId,
        userId,
        status: ParticipantStatus.ATTENDING,
      });
      await this.participantRepository.save(participant);
    }

    // Update attendee count
    event.updateAttendeeCount();
    await this.eventRepository.save(event);

    return { message: 'RSVP successful' };
  }

  async cancelRsvp(eventId: string, userId: string) {
    const participant = await this.participantRepository.findOne({
      where: { eventId, userId },
    });

    if (participant) {
      await this.participantRepository.remove(participant);

      // Update attendee count
      const event = await this.eventRepository.findOne({ where: { id: eventId } });
      if (event) {
        event.updateAttendeeCount();
        await this.eventRepository.save(event);
      }
    }

    return { message: 'RSVP cancelled' };
  }

  async createEvent(createEventDto: any, creatorId: string): Promise<FeedItemDto> {
    const event = this.eventRepository.create({
      ...createEventDto,
      creatorUserId: creatorId,
    });

    const savedEvent = await this.eventRepository.save(event);

    // Load with creator relation
    const eventWithCreator = await this.eventRepository.findOne({
      where: { id: savedEvent.id },
      relations: ['creator'],
    });

    return this.mapEventToFeedItem(eventWithCreator);
  }

  private mapEventToFeedItem(event: Event): FeedItemDto {
    return {
      id: event.id,
      type: FeedItemType.EVENT,
      title: event.title,
      content: event.eventDescription,
      authorId: event.creatorUserId,
      authorName: event.creator?.displayName || 'Unknown User',
      authorAvatar: event.creator?.profileImageUrl,
      createdAt: event.createdAt,
      eventDate: event.date,
      eventLocation: event.location,
      eventType: event.eventType,
      eventEndDate: event.eventEndDate,
      eventAddress: event.eventAddress,
      eventDuration: event.eventDuration,
      eventFormat: event.eventFormat,
      eventNote: event.eventNote,
      eventDetailedDescription: event.eventDetailedDescription,
      heroImageUrl: event.heroImageUrl,
      organizerFollowers: event.organizerFollowers,
      organizerEventsCount: event.organizerEventsCount,
      organizerYearsActive: event.organizerYearsActive,
    };
  }
}