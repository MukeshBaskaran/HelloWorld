/**
*   @description:  This class represents a result for a LiveText action.
*                  It simply contains a boolean indicating success or failure and an accompanying
*                  error message in the case of failure.
*/
global class ActionResult {

  @InvocableVariable(label='Success' description='Status of action')
  global Boolean IsSuccess;

  @InvocableVariable(label='Error Message' description='Error message if action failed')
  global String ErrorMessage;

  @InvocableVariable(label='Tag' description='Object that generated this result')
  global Id Tag;

  public ActionResult(Id tag) {
    IsSuccess = true;
    this.Tag = tag;
  }

  /**
  *   @description Sets an error message for this result. Also sets the IsSuccess status to false to indicate failure.
  *
  *   @Param Error message for this result.
  *
  *   @Return void.
  **/         
  public void SetError(String errorMsg) {
    IsSuccess = false;
    ErrorMessage = errorMsg;
  }

}
