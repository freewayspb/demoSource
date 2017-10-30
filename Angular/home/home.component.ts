import {
  Component,
  OnInit
} from '@angular/core';

import { AppState } from '../app.service';
import { HomeService } from './home.service';

@Component({
  selector: 'home',
  providers: [
    HomeService
  ],
  templateUrl: './home.component.html'
})
export class HomeComponent implements OnInit {
  public localState = { value: '' };
  public title: string = 'Your title';

  constructor(
    public appState: AppState,
    private homeService: HomeService
  ) {}

  public ngOnInit() {
    this.homeService
      .getTitle()
      .subscribe((title) => {
        this.title = title;
      });
  }

  public submitState(value: string) {
    this.appState.set('value', value);
    this.localState.value = '';
  }
}
