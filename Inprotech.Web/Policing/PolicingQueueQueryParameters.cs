using Inprotech.Infrastructure.Web;

namespace Inprotech.Web.Policing
{
    public static class PolicingQueueQueryParameters
    {
        static readonly CommonQueryParameters DefaultQueryParameters =
            CommonQueryParameters.Default.Extend(new CommonQueryParameters
                                                 {
                                                     SortBy = "Requested",
                                                     SortDir = "asc"
                                                 });

        public static CommonQueryParameters Get(CommonQueryParameters queryParameters)
        {
            return DefaultQueryParameters
                .Extend(queryParameters)
                .RemapFilter("user", "userKey");
        }
    }
}