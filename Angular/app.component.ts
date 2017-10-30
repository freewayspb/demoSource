import {
  Component,
  OnInit
} from '@angular/core';
import { AppState } from './app.service';

@Component({
  selector: 'app',
  styleUrls: [
    './app.component.css'
  ],
  template: `
    <nav>
      <a [routerLink]="['./']"
        routerLinkActive="active" [routerLinkActiveOptions]= "{exact: true}">
        Index
      </a>
      <a [routerLink]="['./home']"
        routerLinkActive="active" [routerLinkActiveOptions]= "{exact: true}">
        Home
      </a>
    </nav>

    <main>
      <router-outlet></router-outlet>
    </main>

    <span class="app-state">this.appState.state = {{ appState.state | json }}</span>

    <footer>
      <span>Angular example</span>
    </footer>
  `
})
export class AppComponent implements OnInit {
  public name = 'Angular example';

  constructor(
    public appState: AppState
  ) {}

  public ngOnInit() {
    console.log('Initial App State', this.appState.state);
  }

}
