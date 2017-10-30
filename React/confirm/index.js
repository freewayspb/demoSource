// @flow

import * as React from 'react';
import { connect } from 'react-redux';
import Dialog from 'material-ui/Dialog';
import FlatButton from 'material-ui/FlatButton';
import { confirmClose } from './actions/confirm-dialog';

export interface ConfirmDialogState {
}

type PropTypes = {
  confirmId: string,
  title: string,
  message: string,
  confirmActions: Array<React.Element<any>>,
  confirmClose: (confirmId: string) => void,
  handleConfirm: Function,
  handleDismiss: Function,
}

class ConfirmDialog extends React.Component<PropTypes> {
  getConfirmActions() {
    const defaultActions = [<FlatButton
      label="Отмена"
      primary
      onTouchTap={ this.props.handleDismiss || this.handleDismiss }
    />];
    const additionalActions = this.props.confirmActions ? [...this.props.confirmActions] :
      [<FlatButton
        label="Подвтердить"
        primary
        keyboardFocused
        onTouchTap={ this.props.handleConfirm }
      />];

    return [
      ...defaultActions,
      ...additionalActions,
    ];
  }

  handleDismiss = () => {
    const { confirmId } = this.props;

    this.props.confirmClose(confirmId);
  };


  render() {
    const actions = this.getConfirmActions();

    return (
      <div>
        <Dialog
          title={ this.props.title }
          actions={ actions }
          modal={ false }
          open={ this.props.isOpen || false }
          handleConfirm={ this.props.handleConfirm }
          onRequestClose={ this.props.handleConfirm }
        >
          { this.props.message }
        </Dialog>
      </div>
    );
  }
}

const mapStateToProps = (state, ownProps) => {
  const { handleConfirm, confirmId } = ownProps;
  const { utils: { confirm: { [confirmId]: isOpen } } } = state;

  return {
    confirmId,
    isOpen,
    handleConfirm,
  };
};

const mapDispatchToProps = {
  confirmClose,
};

export default connect(mapStateToProps, mapDispatchToProps)(ConfirmDialog);
