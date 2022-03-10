using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.IPPlatform.FileApp.Post
{
    public interface ITrademarkImageResolver
    {
        Task<TrademarkImage> Resolve(int caseId);
    }

    public class TrademarkImageResolver : ITrademarkImageResolver
    {
        readonly IDbContext _dbContext;
        readonly ISiteControlReader _siteControlReader;

        public TrademarkImageResolver(IDbContext dbContext, ISiteControlReader siteControlReader)
        {
            _dbContext = dbContext;
            _siteControlReader = siteControlReader;
        }

        public async Task<TrademarkImage> Resolve(int caseId)
        {
            var imageTypes = (_siteControlReader.Read<string>(SiteControls.FILETMImageType) ?? string.Empty)
                .Split(new[] {","}, StringSplitOptions.RemoveEmptyEntries)
                .Select(int.Parse)
                .ToArray();

            var allPreferred = from c in _dbContext.Set<CaseImage>()
                               where c.CaseId == caseId && imageTypes.Contains(c.ImageType)
                               select new
                               {
                                   c.ImageType,
                                   c.ImageSequence,
                                   c.ImageId
                               };

            var candidates = await (from a in allPreferred
                                    group a by a.ImageType
                                    into g1
                                    select new
                                    {
                                        ImageType = g1.Key,
                                        g1.FirstOrDefault(_ => _.ImageSequence == g1.Min(m => m.ImageSequence)).ImageId
                                    }).ToArrayAsync();

            var imageId = (int?) null;
            var imageType = (int?) null;

            foreach (var i in imageTypes)
            {
                var c = candidates.FirstOrDefault(_ => _.ImageType == i);
                if (c == null)
                {
                    continue;
                }

                imageId = c.ImageId;
                imageType = c.ImageType;
                break;
            }

            if (imageId.HasValue)
            {
                return await (
                    from ci in _dbContext.Set<CaseImage>()
                    where ci.ImageId == imageId && ci.ImageType == imageType && ci.CaseId == caseId
                    select new TrademarkImage
                    {
                        CaseId = ci.CaseId,
                        CaseReference = ci.Case.Irn,
                        ImageDescription = ci.CaseImageDescription,
                        ContentType = ci.Image.Detail.ContentType,
                        Image = ci.Image.ImageData
                    }).SingleAsync();
            }

            return null;
        }
    }

    public class TrademarkImage
    {
        public int CaseId { get; set; }

        public string CaseReference { get; set; }

        public string ContentType { get; set; }

        public string ImageDescription { get; set; }

        public byte[] Image { get; set; }
    }
}