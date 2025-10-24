import { Test, TestingModule } from '@nestjs/testing';
import { LegislatorsController } from './legislators.controller';
import { LegislatorsService } from './legislators.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { NotFoundException, ConflictException } from '@nestjs/common';

describe('LegislatorsController', () => {
  let controller: LegislatorsController;
  let service: LegislatorsService;

  const mockLegislatorsService = {
    findAll: jest.fn(),
    findOne: jest.fn(),
    findByState: jest.fn(),
    getStats: jest.fn(),
    followLegislator: jest.fn(),
    unfollowLegislator: jest.fn(),
    getDonors: jest.fn(),
    getVotes: jest.fn(),
    getPressReleases: jest.fn(),
  };

  const mockUser = { id: 'user-123', email: 'test@example.com' };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [LegislatorsController],
      providers: [
        {
          provide: LegislatorsService,
          useValue: mockLegislatorsService,
        },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({ canActivate: () => true })
      .compile();

    controller = module.get<LegislatorsController>(LegislatorsController);
    service = module.get<LegislatorsService>(LegislatorsService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('findAll', () => {
    it('should return paginated list of legislators with correct format', async () => {
      const mockResponse = {
        legislators: [
          {
            id: 'legislator-1',
            firstName: 'Alma',
            lastName: 'Adams',
            photoUrl: 'https://example.com/photo.jpg',
            chamber: 'house',
            state: 'NC',
            district: '12',
            party: 'Democrat',
            yearsInOffice: 10,
            followerCount: 1500,
            bioguideId: 'A000370',
            isFollowing: false,
          },
        ],
        total: 1,
        limit: 50,
        offset: 0,
        hasMore: false,
      };

      mockLegislatorsService.findAll.mockResolvedValue(mockResponse);

      const result = await controller.findAll({}, mockUser);

      expect(service.findAll).toHaveBeenCalledWith({}, 'user-123');
      expect(result).toEqual(mockResponse);
      expect(result.legislators).toBeInstanceOf(Array);
      expect(result.legislators[0]).toHaveProperty('id');
      expect(result.legislators[0]).toHaveProperty('firstName');
      expect(result.legislators[0]).toHaveProperty('lastName');
      expect(result.legislators[0]).toHaveProperty('isFollowing');
      expect(result).toHaveProperty('total');
      expect(result).toHaveProperty('hasMore');
    });

    it('should filter legislators by state', async () => {
      const mockResponse = {
        legislators: [],
        total: 0,
        limit: 50,
        offset: 0,
        hasMore: false,
      };

      mockLegislatorsService.findAll.mockResolvedValue(mockResponse);

      await controller.findAll({ state: 'NC' }, mockUser);

      expect(service.findAll).toHaveBeenCalledWith({ state: 'NC' }, 'user-123');
    });

    it('should filter legislators by chamber', async () => {
      const mockResponse = {
        legislators: [],
        total: 0,
        limit: 50,
        offset: 0,
        hasMore: false,
      };

      mockLegislatorsService.findAll.mockResolvedValue(mockResponse);

      await controller.findAll({ chamber: 'senate' }, mockUser);

      expect(service.findAll).toHaveBeenCalledWith({ chamber: 'senate' }, 'user-123');
    });

    it('should handle pagination correctly', async () => {
      const mockResponse = {
        legislators: [],
        total: 100,
        limit: 20,
        offset: 40,
        hasMore: true,
      };

      mockLegislatorsService.findAll.mockResolvedValue(mockResponse);

      await controller.findAll({ limit: 20, offset: 40 }, mockUser);

      expect(service.findAll).toHaveBeenCalledWith({ limit: 20, offset: 40 }, 'user-123');
    });
  });

  describe('findOne', () => {
    it('should return legislator details with correct format', async () => {
      const mockLegislator = {
        id: 'legislator-1',
        firstName: 'Alma',
        lastName: 'Adams',
        photoUrl: 'https://example.com/photo.jpg',
        chamber: 'house',
        state: 'NC',
        district: '12',
        party: 'Democrat',
        yearsInOffice: 10,
        followerCount: 1500,
        bioguideId: 'A000370',
        isFollowing: true,
        committees: [
          {
            id: 'comm-1',
            committeeName: 'House Committee on Financial Services',
            role: 'Member',
          },
        ],
        topDonors: [
          {
            id: 'donor-1',
            name: 'American Federation of Teachers',
            type: 'PAC',
            amount: '10000.00',
            formattedAmount: '$10,000',
            date: new Date('2024-03-15'),
          },
        ],
        recentVotes: [
          {
            id: 'vote-1',
            billId: 'bill-1',
            billTitle: 'Education Funding Enhancement Act',
            billNumber: 'HR-1234',
            position: 'Yes',
            timestamp: new Date('2024-01-22'),
            aligned: true,
          },
        ],
      };

      mockLegislatorsService.findOne.mockResolvedValue(mockLegislator);

      const result = await controller.findOne('legislator-1', mockUser);

      expect(service.findOne).toHaveBeenCalledWith('legislator-1', 'user-123');
      expect(result).toEqual(mockLegislator);

      // Verify data structure matches frontend expectations
      expect(result).toHaveProperty('isFollowing');
      expect(result.committees).toBeInstanceOf(Array);
      expect(result.topDonors).toBeInstanceOf(Array);
      expect(result.topDonors[0].amount).toBe('10000.00'); // Should be string
      expect(result.recentVotes).toBeInstanceOf(Array);
    });

    it('should throw NotFoundException when legislator not found', async () => {
      mockLegislatorsService.findOne.mockRejectedValue(
        new NotFoundException('Legislator with ID nonexistent not found'),
      );

      await expect(controller.findOne('nonexistent', mockUser)).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('followLegislator', () => {
    it('should follow legislator successfully', async () => {
      const mockResponse = {
        message: 'Successfully followed legislator',
        followerCount: 1501,
      };

      mockLegislatorsService.followLegislator.mockResolvedValue(mockResponse);

      const result = await controller.followLegislator('legislator-1', mockUser);

      expect(service.followLegislator).toHaveBeenCalledWith('legislator-1', 'user-123');
      expect(result).toEqual(mockResponse);
      expect(result).toHaveProperty('message');
      expect(result).toHaveProperty('followerCount');
      expect(typeof result.followerCount).toBe('number');
    });

    it('should throw ConflictException when already following', async () => {
      mockLegislatorsService.followLegislator.mockRejectedValue(
        new ConflictException('You are already following this legislator'),
      );

      await expect(controller.followLegislator('legislator-1', mockUser)).rejects.toThrow(
        ConflictException,
      );
    });

    it('should throw NotFoundException when legislator not found', async () => {
      mockLegislatorsService.followLegislator.mockRejectedValue(
        new NotFoundException('Legislator with ID nonexistent not found'),
      );

      await expect(controller.followLegislator('nonexistent', mockUser)).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('unfollowLegislator', () => {
    it('should unfollow legislator successfully', async () => {
      const mockResponse = {
        message: 'Successfully unfollowed legislator',
        followerCount: 1499,
      };

      mockLegislatorsService.unfollowLegislator.mockResolvedValue(mockResponse);

      const result = await controller.unfollowLegislator('legislator-1', mockUser);

      expect(service.unfollowLegislator).toHaveBeenCalledWith('legislator-1', 'user-123');
      expect(result).toEqual(mockResponse);
      expect(result).toHaveProperty('message');
      expect(result).toHaveProperty('followerCount');
      expect(typeof result.followerCount).toBe('number');
    });

    it('should throw NotFoundException when not following', async () => {
      mockLegislatorsService.unfollowLegislator.mockRejectedValue(
        new NotFoundException('You are not following this legislator'),
      );

      await expect(controller.unfollowLegislator('legislator-1', mockUser)).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('getDonors', () => {
    it('should return paginated donors with correct format', async () => {
      const mockResponse = {
        donors: [
          {
            id: 'donor-1',
            name: 'American Federation of Teachers',
            type: 'PAC',
            amount: '10000.00',
            formattedAmount: '$10,000',
            date: new Date('2024-03-15'),
          },
          {
            id: 'donor-2',
            name: 'National Education Association',
            type: 'PAC',
            amount: '8500.00',
            formattedAmount: '$8,500',
            date: new Date('2024-02-20'),
          },
        ],
        total: 10,
        limit: 50,
        offset: 0,
        hasMore: false,
      };

      mockLegislatorsService.getDonors.mockResolvedValue(mockResponse);

      const result = await controller.getDonors('legislator-1', 50, 0);

      expect(service.getDonors).toHaveBeenCalledWith('legislator-1', {
        limit: 50,
        offset: 0,
        type: undefined,
      });
      expect(result).toEqual(mockResponse);
      expect(result.donors).toBeInstanceOf(Array);
      expect(result.donors[0]).toHaveProperty('amount');
      expect(typeof result.donors[0].amount).toBe('string'); // Amount should be string
      expect(result.donors[0]).toHaveProperty('formattedAmount');
      expect(result).toHaveProperty('total');
      expect(result).toHaveProperty('hasMore');
    });

    it('should filter donors by type', async () => {
      const mockResponse = {
        donors: [],
        total: 0,
        limit: 50,
        offset: 0,
        hasMore: false,
      };

      mockLegislatorsService.getDonors.mockResolvedValue(mockResponse);

      await controller.getDonors('legislator-1', 50, 0, 'pac');

      expect(service.getDonors).toHaveBeenCalledWith('legislator-1', {
        limit: 50,
        offset: 0,
        type: 'pac',
      });
    });
  });

  describe('getVotes', () => {
    it('should return paginated votes with correct format', async () => {
      const mockResponse = {
        votes: [
          {
            id: 'vote-1',
            billId: 'bill-1',
            billTitle: 'Education Funding Enhancement Act',
            billNumber: 'HR-1234',
            position: 'Yes',
            timestamp: new Date('2024-01-22'),
            aligned: true,
          },
          {
            id: 'vote-2',
            billId: 'bill-2',
            billTitle: 'Healthcare Reform Act',
            billNumber: 'HR-5678',
            position: 'No',
            timestamp: new Date('2024-01-20'),
            aligned: false,
          },
        ],
        total: 5,
        limit: 50,
        offset: 0,
        hasMore: false,
      };

      mockLegislatorsService.getVotes.mockResolvedValue(mockResponse);

      const result = await controller.getVotes('legislator-1', 50, 0);

      expect(service.getVotes).toHaveBeenCalledWith('legislator-1', {
        limit: 50,
        offset: 0,
      });
      expect(result).toEqual(mockResponse);
      expect(result.votes).toBeInstanceOf(Array);
      expect(result.votes[0]).toHaveProperty('billId');
      expect(result.votes[0]).toHaveProperty('billTitle');
      expect(result.votes[0]).toHaveProperty('position');
      expect(result.votes[0]).toHaveProperty('aligned');
      expect(result).toHaveProperty('total');
      expect(result).toHaveProperty('hasMore');
    });
  });

  describe('getPressReleases', () => {
    it('should return paginated press releases with correct format', async () => {
      const mockResponse = {
        pressReleases: [
          {
            id: 'press-1',
            title: 'Rep. Adams Announces Funding for Local Schools',
            description: 'New education initiative brings $5M to district schools',
            thumbnailUrl: 'https://example.com/thumb.jpg',
            publishedAt: new Date('2024-01-15'),
          },
        ],
        total: 1,
        limit: 50,
        offset: 0,
        hasMore: false,
      };

      mockLegislatorsService.getPressReleases.mockResolvedValue(mockResponse);

      const result = await controller.getPressReleases('legislator-1', 50, 0);

      expect(service.getPressReleases).toHaveBeenCalledWith('legislator-1', {
        limit: 50,
        offset: 0,
      });
      expect(result).toEqual(mockResponse);
      expect(result.pressReleases).toBeInstanceOf(Array);
      expect(result.pressReleases[0]).toHaveProperty('title');
      expect(result.pressReleases[0]).toHaveProperty('description');
      expect(result.pressReleases[0]).toHaveProperty('publishedAt');
      expect(result).toHaveProperty('total');
      expect(result).toHaveProperty('hasMore');
    });
  });

  describe('getStats', () => {
    it('should return statistics with correct format', async () => {
      const mockStats = {
        total: 535,
        senators: 100,
        representatives: 435,
        byParty: {
          Democrat: 220,
          Republican: 212,
          Independent: 3,
        },
      };

      mockLegislatorsService.getStats.mockResolvedValue(mockStats);

      const result = await controller.getStats();

      expect(service.getStats).toHaveBeenCalled();
      expect(result).toEqual(mockStats);
      expect(result).toHaveProperty('total');
      expect(result).toHaveProperty('senators');
      expect(result).toHaveProperty('representatives');
      expect(result).toHaveProperty('byParty');
      expect(typeof result.byParty).toBe('object');
    });
  });

  describe('findByState', () => {
    it('should return legislators from a specific state', async () => {
      const mockLegislators = [
        {
          id: 'legislator-1',
          firstName: 'Alma',
          lastName: 'Adams',
          state: 'NC',
          chamber: 'house',
          district: '12',
        },
      ];

      mockLegislatorsService.findByState.mockResolvedValue(mockLegislators);

      const result = await controller.findByState('NC');

      expect(service.findByState).toHaveBeenCalledWith('NC');
      expect(result).toEqual(mockLegislators);
      expect(result).toBeInstanceOf(Array);
    });
  });

  describe('API Contract Validation', () => {
    it('should ensure donor amount is returned as string, not number', async () => {
      const mockLegislator = {
        id: 'legislator-1',
        firstName: 'Alma',
        lastName: 'Adams',
        topDonors: [
          {
            id: 'donor-1',
            name: 'Test Donor',
            type: 'PAC',
            amount: '10000.00', // This should be a string
            formattedAmount: '$10,000',
            date: new Date(),
          },
        ],
      };

      mockLegislatorsService.findOne.mockResolvedValue(mockLegislator);

      const result = await controller.findOne('legislator-1', mockUser);

      expect(typeof result.topDonors[0].amount).toBe('string');
      expect(result.topDonors[0].amount).toMatch(/^\d+\.\d{2}$/);
    });

    it('should ensure followerCount is a number', async () => {
      const mockResponse = {
        message: 'Successfully followed legislator',
        followerCount: 1500,
      };

      mockLegislatorsService.followLegislator.mockResolvedValue(mockResponse);

      const result = await controller.followLegislator('legislator-1', mockUser);

      expect(typeof result.followerCount).toBe('number');
    });

    it('should ensure pagination fields are present and correct types', async () => {
      const mockResponse = {
        legislators: [],
        total: 100,
        limit: 50,
        offset: 0,
        hasMore: true,
      };

      mockLegislatorsService.findAll.mockResolvedValue(mockResponse);

      const result = await controller.findAll({}, mockUser);

      expect(typeof result.total).toBe('number');
      expect(typeof result.limit).toBe('number');
      expect(typeof result.offset).toBe('number');
      expect(typeof result.hasMore).toBe('boolean');
    });
  });
});
