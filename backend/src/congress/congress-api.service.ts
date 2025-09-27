import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios, { AxiosInstance } from 'axios';
import { Party } from '../users/entities/legislator-profile.entity';

export interface CongressMember {
  bioguideId: string;
  firstName: string;
  lastName: string;
  party: string;
  state: string;
  district?: string;
  chamber: 'house' | 'senate';
  termStart: string;
  termEnd: string;
  photoUrl?: string;
}

export interface CongressApiResponse {
  members: Array<{
    bioguide_id: string;
    first_name: string;
    last_name: string;
    party: string;
    state: string;
    district?: string;
    short_title: string;
    date_of_birth: string;
    in_office: boolean;
    next_election: string;
    phone?: string;
    office?: string;
    contact_form?: string;
  }>;
}

@Injectable()
export class CongressApiService {
  private readonly logger = new Logger(CongressApiService.name);
  private readonly httpClient: AxiosInstance;
  private readonly apiKey: string;
  private readonly baseUrl: string;

  constructor(private configService: ConfigService) {
    this.apiKey = this.configService.get<string>('CONGRESS_API_KEY');
    this.baseUrl = this.configService.get<string>('CONGRESS_API_BASE_URL');

    this.httpClient = axios.create({
      baseURL: this.baseUrl,
      headers: {
        'X-API-Key': this.apiKey,
        'Accept': 'application/json',
      },
      timeout: 10000,
    });
  }

  async getCurrentMembers(): Promise<CongressMember[]> {
    this.logger.log('Fetching current Congress members from API');

    try {
      const allMembers: CongressMember[] = [];
      let offset = 0;
      const limit = 250; // Maximum allowed limit
      let hasMore = true;

      while (hasMore) {
        this.logger.log(`Fetching members with offset ${offset}...`);

        const response = await this.httpClient.get('/member/congress/118', {
          params: {
            currentMember: 'True',
            limit,
            offset,
            format: 'json'
          }
        });

        const pageMembers = this.parseMembers(response.data);
        allMembers.push(...pageMembers);

        // Check if there are more pages
        const pagination = response.data?.pagination;
        hasMore = !!pagination?.next;
        offset += limit;

        this.logger.log(`Fetched ${pageMembers.length} members, total so far: ${allMembers.length}`);

        // Small delay to be respectful to the API
        if (hasMore) {
          await new Promise(resolve => setTimeout(resolve, 500));
        }
      }

      this.logger.log(`Fetched ${allMembers.length} total members`);
      return allMembers;
    } catch (error) {
      this.logger.error('Failed to fetch Congress members', error.stack);
      throw new Error('Failed to fetch Congress members from API');
    }
  }

  private parseMembers(data: any): CongressMember[] {
    if (!data?.members) {
      this.logger.warn(`No members found in API response`);
      return [];
    }

    const members = data.members;
    return members.map((member: any) => {
      // Parse the name (format: "Last, First" or "Last, First Middle")
      const nameParts = member.name?.split(', ') || [];
      const lastName = nameParts[0] || '';
      const firstNames = nameParts[1]?.split(' ') || [''];
      const firstName = firstNames[0] || '';

      // Determine chamber based on terms
      const latestTerm = member.terms?.item?.[member.terms.item.length - 1];
      const chamber: 'house' | 'senate' =
        latestTerm?.chamber === 'Senate' || member.district === undefined ? 'senate' : 'house';

      return {
        bioguideId: member.bioguideId,
        firstName,
        lastName,
        party: this.mapParty(member.partyName),
        state: this.mapStateNameToCode(member.state),
        district: chamber === 'house' ? member.district?.toString() : null,
        chamber,
        termStart: latestTerm?.startYear?.toString() || '2023',
        termEnd: '2025', // 118th Congress ends in 2025
        photoUrl: member.depiction?.imageUrl || this.buildPhotoUrl(member.bioguideId),
      };
    });
  }

  private mapParty(party: string): Party {
    switch (party?.toUpperCase()) {
      case 'D':
      case 'DEMOCRAT':
      case 'DEMOCRATIC':
        return Party.DEMOCRAT;
      case 'R':
      case 'REPUBLICAN':
        return Party.REPUBLICAN;
      case 'I':
      case 'INDEPENDENT':
        return Party.INDEPENDENT;
      case 'GREEN':
        return Party.GREEN;
      case 'LIBERTARIAN':
        return Party.LIBERTARIAN;
      default:
        this.logger.warn(`Unknown party: ${party}, defaulting to Independent`);
        return Party.INDEPENDENT;
    }
  }

  private buildPhotoUrl(bioguideId: string): string {
    // Official Congressional photo directory
    return `https://bioguide.congress.gov/bioguide/photo/${bioguideId.charAt(0)}/${bioguideId}.jpg`;
  }

  private mapStateNameToCode(stateName: string): string {
    const stateMap: Record<string, string> = {
      'Alabama': 'AL', 'Alaska': 'AK', 'Arizona': 'AZ', 'Arkansas': 'AR', 'California': 'CA',
      'Colorado': 'CO', 'Connecticut': 'CT', 'Delaware': 'DE', 'Florida': 'FL', 'Georgia': 'GA',
      'Hawaii': 'HI', 'Idaho': 'ID', 'Illinois': 'IL', 'Indiana': 'IN', 'Iowa': 'IA',
      'Kansas': 'KS', 'Kentucky': 'KY', 'Louisiana': 'LA', 'Maine': 'ME', 'Maryland': 'MD',
      'Massachusetts': 'MA', 'Michigan': 'MI', 'Minnesota': 'MN', 'Mississippi': 'MS', 'Missouri': 'MO',
      'Montana': 'MT', 'Nebraska': 'NE', 'Nevada': 'NV', 'New Hampshire': 'NH', 'New Jersey': 'NJ',
      'New Mexico': 'NM', 'New York': 'NY', 'North Carolina': 'NC', 'North Dakota': 'ND', 'Ohio': 'OH',
      'Oklahoma': 'OK', 'Oregon': 'OR', 'Pennsylvania': 'PA', 'Rhode Island': 'RI', 'South Carolina': 'SC',
      'South Dakota': 'SD', 'Tennessee': 'TN', 'Texas': 'TX', 'Utah': 'UT', 'Vermont': 'VT',
      'Virginia': 'VA', 'Washington': 'WA', 'West Virginia': 'WV', 'Wisconsin': 'WI', 'Wyoming': 'WY',
      'District of Columbia': 'DC', 'Puerto Rico': 'PR', 'Guam': 'GU', 'US Virgin Islands': 'VI',
      'American Samoa': 'AS', 'Northern Mariana Islands': 'MP'
    };

    return stateMap[stateName] || stateName.substring(0, 2).toUpperCase();
  }

  async getMemberDetails(bioguideId: string): Promise<any> {
    try {
      const response = await this.httpClient.get(`/member/${bioguideId}`);
      return response.data;
    } catch (error) {
      this.logger.error(`Failed to fetch details for ${bioguideId}`, error.stack);
      return null;
    }
  }

  // Helper method to calculate years in office
  calculateYearsInOffice(startDate: string): number {
    const start = new Date(startDate);
    const now = new Date();
    const years = now.getFullYear() - start.getFullYear();
    return years > 0 ? years : 0;
  }
}