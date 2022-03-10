using System.Linq;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Cases.Details
{
    public interface IDefaultCaseImage
    {
        CaseImage For(int caseId);
    }

    public class DefaultCaseImage : IDefaultCaseImage
    {
        readonly IDbContext _dbContext;

        public DefaultCaseImage(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public CaseImage For(int caseId)
        {
            var setting = (from sc in _dbContext.Set<SiteControl>()
                           where sc.ControlId == SiteControls.CaseViewSummaryImageType
                           select sc.StringValue).FirstOrDefault();

            if (setting == null)
            {
                return null;
            }

            var caseImages = from ci in _dbContext.Set<CaseImage>()
                             where ci.CaseId == caseId
                             orderby ci.ImageSequence
                             select ci;

            return (from imageType in setting.Split(',')
                    from image in caseImages
                    where image.ImageType.ToString() == imageType.Trim()
                    select image).FirstOrDefault();
        }
    }
}