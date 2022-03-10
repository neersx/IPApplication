namespace Inprotech.IntegrationServer.PtoAccess.Innography
{
    public static class InnographyTradeMarksApiSettings
    {  
        public static readonly string TargetApiVersion = "2.1.0";
        public static readonly string Requester = "inprotech";
        public static readonly string Destination = "ip1d";
        public static readonly string MessageType = "tm_match";
    }

    public static class InnographyPatentsApiSettings
    {  
        public static readonly string TargetApiVersion = "0.8";
        public static readonly string GuidChangesTargetApiVersion = "0.8";
    }
}
