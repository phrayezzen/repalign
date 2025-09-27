import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  getHealth(): { status: string; message: string; timestamp: string } {
    return {
      status: 'ok',
      message: 'RepAlign API is running successfully',
      timestamp: new Date().toISOString(),
    };
  }

  getVersion(): { version: string; name: string } {
    return {
      name: 'RepAlign API',
      version: '1.0.0',
    };
  }
}