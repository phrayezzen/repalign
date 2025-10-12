import { Test, TestingModule } from '@nestjs/testing';
import { CongressController } from './congress.controller';
import { EventService } from './events.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

describe('CongressController', () => {
  let controller: CongressController;
  let eventService: EventService;

  const mockEventService = {
    getEventById: jest.fn(),
    rsvpToEvent: jest.fn(),
    cancelRsvp: jest.fn(),
    createEvent: jest.fn(),
  };

  const mockUser = { id: 'user-123' };
  const mockRequest = { user: mockUser };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [CongressController],
      providers: [
        {
          provide: EventService,
          useValue: mockEventService,
        },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({ canActivate: () => true })
      .compile();

    controller = module.get<CongressController>(CongressController);
    eventService = module.get<EventService>(EventService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('rsvpToEvent', () => {
    it('should RSVP to an event successfully', async () => {
      const eventId = 'event-123';
      const mockResult = {
        success: true,
        message: 'RSVP successful',
        eventId,
        userId: 'user-123'
      };

      mockEventService.rsvpToEvent.mockResolvedValue(mockResult);

      const result = await controller.rsvpToEvent(eventId, mockRequest);

      expect(eventService.rsvpToEvent).toHaveBeenCalledWith('event-123', 'user-123');
      expect(result).toEqual(mockResult);
    });

    it('should handle RSVP errors', async () => {
      const eventId = 'event-123';
      const error = new Error('Event not found');

      mockEventService.rsvpToEvent.mockRejectedValue(error);

      await expect(controller.rsvpToEvent(eventId, mockRequest)).rejects.toThrow('Event not found');
    });

    it('should handle duplicate RSVP attempts', async () => {
      const eventId = 'event-123';
      const error = new Error('User already RSVPed to this event');

      mockEventService.rsvpToEvent.mockRejectedValue(error);

      await expect(controller.rsvpToEvent(eventId, mockRequest)).rejects.toThrow('User already RSVPed to this event');
    });
  });

  describe('cancelRsvp', () => {
    it('should cancel RSVP successfully', async () => {
      const eventId = 'event-123';
      const mockResult = {
        success: true,
        message: 'RSVP cancelled',
        eventId,
        userId: 'user-123'
      };

      mockEventService.cancelRsvp.mockResolvedValue(mockResult);

      const result = await controller.cancelRsvp(eventId, mockRequest);

      expect(eventService.cancelRsvp).toHaveBeenCalledWith('event-123', 'user-123');
      expect(result).toEqual(mockResult);
    });

    it('should handle cancel RSVP errors', async () => {
      const eventId = 'event-123';
      const error = new Error('No RSVP found for this event');

      mockEventService.cancelRsvp.mockRejectedValue(error);

      await expect(controller.cancelRsvp(eventId, mockRequest)).rejects.toThrow('No RSVP found for this event');
    });
  });

  describe('getEvent', () => {
    it('should get event by ID', async () => {
      const eventId = 'event-123';
      const mockEvent = {
        id: eventId,
        title: 'Town Hall Meeting',
        type: 'event',
        content: 'Community discussion',
        authorId: 'legislator-123',
        authorName: 'Senator Smith',
        eventDate: new Date(),
        eventLocation: 'Community Center',
      };

      mockEventService.getEventById.mockResolvedValue(mockEvent);

      const result = await controller.getEvent(eventId);

      expect(eventService.getEventById).toHaveBeenCalledWith('event-123');
      expect(result).toEqual(mockEvent);
    });

    it('should handle event not found', async () => {
      const eventId = 'nonexistent-event';
      const error = new Error('Event not found');

      mockEventService.getEventById.mockRejectedValue(error);

      await expect(controller.getEvent(eventId)).rejects.toThrow('Event not found');
    });
  });

  describe('createEvent', () => {
    it('should create event successfully', async () => {
      const createEventDto = {
        title: 'New Town Hall',
        content: 'Community discussion about local issues',
        eventDate: new Date(),
        eventLocation: 'City Hall',
        eventType: 'Town Hall',
      };

      const mockEvent = {
        id: 'new-event-123',
        ...createEventDto,
        authorId: 'user-123',
        type: 'event',
      };

      mockEventService.createEvent.mockResolvedValue(mockEvent);

      const result = await controller.createEvent(createEventDto, mockRequest);

      expect(eventService.createEvent).toHaveBeenCalledWith(createEventDto, 'user-123');
      expect(result).toEqual(mockEvent);
    });

    it('should handle create event errors', async () => {
      const createEventDto = {
        title: 'New Town Hall',
        content: 'Community discussion',
      };
      const error = new Error('Invalid event data');

      mockEventService.createEvent.mockRejectedValue(error);

      await expect(controller.createEvent(createEventDto, mockRequest)).rejects.toThrow('Invalid event data');
    });
  });
});