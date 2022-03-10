using System;

namespace Inprotech.IntegrationServer.PtoAccess.Epo
{
    [Serializable]
    public class EpoAuthInvalidResponse : Exception
    {
        public EpoAuthInvalidResponse(string result, Exception innerException)
            : base( string.Format(Properties.PtoAccess.EpoAuthInvalidResponseExceptionMessage, result), innerException)
        {

        }
    }

    [Serializable]
    public class EpoAuthUnauthorizedResponse : Exception
    {
        public EpoAuthUnauthorizedResponse(Exception innerException)
            : base(Properties.PtoAccess.EpoAuthUnauthorizedExceptionMessage, innerException)
        {

        }
    }

    [Serializable]
    public class EpoAuthForbiddenResponse : Exception
    {
        public EpoAuthForbiddenResponse(Exception innerException )
            : base(Properties.PtoAccess.EpoAuthForbiddenExceptionMessage, innerException)
        {

        }
    }

}
