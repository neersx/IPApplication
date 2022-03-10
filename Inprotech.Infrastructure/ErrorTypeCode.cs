namespace Inprotech.Infrastructure
{
    public enum ErrorTypeCode
    {
        /// <summary>
        /// When an unexpected problem occurrs in the system
        /// </summary>
        ServerError, 
        /// <summary>
        /// When required field is missing or an invalid value was supplied
        /// </summary>
        InvalidParameter, 
        PermissionDenied,
        /// <summary>
        /// When contact id to be updated doesnt exists in Inprotech
        /// </summary>
        ContactDoesNotExist,
        /// <summary>
        /// When Action id to be updated doesnt exists in Inprotech
        /// </summary>
        ActionDoesNotExist,

        /// <summary>
        /// When Checklist id to be updated doesnt exists in Inprotech
        /// </summary>
        ChecklistDoesNotExist,
        /// <summary>
        /// When the user doesnt have any of adequate licenses granted i.e CrmWorkbench or MarketingModule
        /// </summary>
        LicenseNotGranted, 
        /// <summary>
        /// When the user doesn't have row access security for given case
        /// </summary>
        NoRowaccessForCase,
        /// <summary>
        /// When the user is prevented access to a given case due to ethical wall
        /// </summary>
        EthicalWallForCase,
        /// <summary>
        /// When the user doesn't have row access security for given name
        /// </summary>
        NoRowaccessForName,
        /// <summary>
        /// When the user is prevented access to a given case due to ethical wall
        /// </summary>
        EthicalWallForName,
        /// <summary>
        /// When the provided response code doesn't exist
        /// </summary>
        ResponseCodeDoesNotExist, 
        /// <summary>
        /// When the provided case doesn't exist
        /// </summary>
        CaseDoesntExist, 
        /// <summary>
        /// When the provided site control Id doesn't exist
        /// </summary>
        SitecontrolNotSet ,
        /// <summary>
        /// When Attributes are not provided and they are required
        /// </summary>
        NameattributesDoesntExist,
        /// <summary>
        /// When contact already associated to provided case
        /// </summary>
        ContactAlreadyExist,
        /// <summary>
        /// When provided attribute does not exist in inprotech database
        /// </summary>
        AttributeNotFound,
        /// <summary>
        /// When provided filename is not valid
        /// </summary>
        NotValidFile,
        /// <summary>
        /// When the provided activity type doesn't exist
        /// </summary>
        ActivityTypeDoesntExist,
        /// <summary>
        /// When the provided activity category doesn't exist
        /// </summary>
        ActivityCategoryDoesntExist,
        /// <summary>
        /// When the provided case is not a crm case
        /// </summary>
        NotACrmCase,
        /// <summary>
        /// when subtype with provided id doesn't exist
        /// </summary>
        SubTypeDoesNotExist,
        /// <summary>
        /// when casetype with provided id doesn't exist
        /// </summary>
        CaseTypeDoesNotExist,
        /// <summary>
        /// when tag with provided id doesn't exist
        /// </summary>
        TagDoesNotExist,
        /// <summary>
        /// when name type group with provided id doesn't exist
        /// </summary>
        NameTypeGroupDoesNotExist,
        /// <summary>
        /// when data item group with provided id doesn't exist
        /// </summary>
        DataItemGroupDoesNotExist,
        /// <summary>
        /// when data item with provided id doesn't exist
        /// </summary>
        DataItemDoesNotExist,
        /// <summary>
        /// External user unauthorised to look up cases that do not have relationship with their Access Account
        /// </summary>
        CaseNotRelatedToExternalUser,
        /// <summary>
        /// External user unauthorised to look up names that do not have relationship with their Access Account
        /// </summary>
        NameNotRelatedToExternalUser,
        /// <summary>
        /// Cases at particular status as defined, would not be accessible to the end user - see 'DefaultSecurity' site control.
        /// </summary>
        NoStatusSecurityForCase,
        /// <summary>
        /// When Question id to be updated doesnt exists in Inprotech
        /// </summary>
        QuestionDoesNotExist
    }
}
