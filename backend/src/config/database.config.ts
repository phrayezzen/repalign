import { DataSource, DataSourceOptions } from 'typeorm';
import { ConfigService } from '@nestjs/config';
import { config } from 'dotenv';

config();

const configService = new ConfigService();

const isSqlite = configService.get('DATABASE_TYPE') === 'sqlite';

const dataSourceOptions: DataSourceOptions = isSqlite
  ? {
      type: 'sqlite',
      database: configService.get('DATABASE_NAME') || './repalign_dev.db',
      entities: [__dirname + '/../**/*.entity{.ts,.js}'],
      migrations: [__dirname + '/../database/migrations/*{.ts,.js}'],
      synchronize: configService.get('NODE_ENV') === 'development',
      logging: configService.get('NODE_ENV') === 'development',
    }
  : {
      type: 'postgres',
      host: configService.get('DATABASE_HOST'),
      port: configService.get('DATABASE_PORT'),
      username: configService.get('DATABASE_USERNAME'),
      password: configService.get('DATABASE_PASSWORD'),
      database: configService.get('DATABASE_NAME'),
      entities: [__dirname + '/../**/*.entity{.ts,.js}'],
      migrations: [__dirname + '/../database/migrations/*{.ts,.js}'],
      synchronize: configService.get('NODE_ENV') === 'development',
      logging: configService.get('NODE_ENV') === 'development',
    };

export const DatabaseConfig = new DataSource(dataSourceOptions);