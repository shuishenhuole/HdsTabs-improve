import { hilog } from '@kit.PerformanceAnalysisKit';

export class Logger {
  private static domain: number = 0xFF00;
  private static tag: string = '[ZSTabs]';

  static setTag(tag: string): void {
    Logger.tag = tag;
  }

  static debug(message: string, ...args: (string | number)[]): void {
    hilog.debug(Logger.domain, Logger.tag, message, ...args);
  }

  static info(message: string, ...args: (string | number)[]): void {
    hilog.info(Logger.domain, Logger.tag, message, ...args);
  }

  static warn(message: string, ...args: (string | number)[]): void {
    hilog.warn(Logger.domain, Logger.tag, message, ...args);
  }

  static error(message: string, ...args: (string | number)[]): void {
    hilog.error(Logger.domain, Logger.tag, message, ...args);
  }

  static fatal(message: string, ...args: (string | number)[]): void {
    hilog.fatal(Logger.domain, Logger.tag, message, ...args);
  }
}