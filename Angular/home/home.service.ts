import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { Http } from '@angular/http';

@Injectable()
export class HomeService {
  constructor(private http: Http) {
  }

  public getTitle(): Observable<string> {
    return this.http
        .get('/data')
        .map((res) => res.json());
  }
}
