namespace Inprotech.Integration.Innography.PrivatePair
{
    public class KnownFileNames
    {
        public static string CpaXml = "cpa-xml.xml";
        public static string ApplicationList = "applicationlist.xml";
        public static string ApplicationDetails = "applicationdetails.xml";
        public static string ImageFileWrapperTab = "ifwtab.html";
        public static string BiblioFileName(ApplicationDownload application) => $"biblio_{application.ApplicationId}.json";
    }
}
