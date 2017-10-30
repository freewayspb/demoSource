// @flow

import * as React from 'react';
import { connect } from 'react-redux';
import hasPermission from 'has-permission';

type PropTypes = {
  children: any,
  hasCreatePermission: boolean,
  hasReadPermission: boolean,
  hasEditPermission: boolean,
}

function PermissionControlled(props: PropTypes) {
  const {
    children,
    hasCreatePermission,
    hasReadPermission,
    hasEditPermission,
  } = props;

  if (!children || !hasReadPermission) {
    return (<div />);
  }
  const isEdit = children.props.itemId;
  const hasPermissions = isEdit ? hasEditPermission : hasCreatePermission;
  return (
    <children.type
      { ...children.props }
      { ...props }
      disabled={ children.props.disabled || !hasPermissions }
      hasEditPermission={ hasPermissions }
    >
      { children.children }
    </children.type>
  );
}

PermissionControlled.defaultProps = {};

const mapStateToProps = (state, ownProps) => {
  const { permissions } = ownProps;

  return {
    ...Object.keys(permissions)
      .map((permissionKey: string) => ({ [permissionKey]: hasPermission(state.auth, permissions[permissionKey]) }))
      .reduce((memo, permission) => ({ ...memo, ...permission }), {}),
  };
};

const mapDispatchToProps = (dispatch: Function) => ({
});

export default connect(mapStateToProps, mapDispatchToProps)(PermissionControlled);

