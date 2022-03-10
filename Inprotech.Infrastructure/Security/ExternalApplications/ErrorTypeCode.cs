namespace Inprotech.Infrastructure.Security.ExternalApplications
{
    internal enum ErrorTypeCode
    {
        /// <summary>
        /// When UserName in http request header is not mapped into Inprotech database
        /// </summary>
        InvalidUser,
        /// <summary>
        /// When Api Key supplied in http request header doesnt exist for Trinogy system in Inprotech database
        /// </summary>
        InvalidApikey,
        /// <summary>
        /// When http request header doesnt contain X-UserName value
        /// </summary>
        UsernameNotProvided,
        /// <summary>
        /// When http request header doesnt contain X-ApiKey value
        /// </summary>
        ApikeyNotProvided,

    }
}
