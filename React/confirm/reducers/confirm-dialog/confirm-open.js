// @flow

export default (state: Object, payload: string) => ({
  ...state,
  [payload]: true,
});
