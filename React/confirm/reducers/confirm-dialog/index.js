// @flow

import confirmDialogCloseReducer from './confirm-close';
import confirmDialogOpenReducer from './confirm-open';

import { confirmClose, confirmOpen } from '../../actions/confirm-dialog';

export default {
  [confirmClose]: confirmDialogCloseReducer,
  [confirmOpen]: confirmDialogOpenReducer,
};
