using System.Linq;
using InprotechKaizen.Model.ContactActivities;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Attachment
{
    public interface IAttachmentContentLoader
    {
        bool TryLoadAttachmentContent(int activityId, int sequence, out AttachmentContentLoader.AttachmentLoadModel content);
    }

    public class AttachmentContentLoader : IAttachmentContentLoader
    {
        readonly IDbContext _dbContext;
        public AttachmentContentLoader(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public bool TryLoadAttachmentContent(int activityId, int sequence, out AttachmentLoadModel content)
        {
            content = null;
            var attachment = _dbContext.Set<ActivityAttachment>()
                                       .SingleOrDefault(a => a.ActivityId == activityId && a.SequenceNo == sequence);

            if (attachment?.Reference == null)
                return false;
        
            var ac = _dbContext.Set<AttachmentContent>()
                               .FirstOrDefault(c => c.Id == attachment.AttachmentContent.Id);

            if (ac == null) return false;
        
            content = new AttachmentLoadModel
            {
                Content = ac.Content,
                ContentType = ac.ContentType,
                FileName = ac.FileName,
                ContentLength = ac.Content.Length
            };

            return true;
        }

        public class AttachmentLoadModel
        {
            public string ContentType { get; set; }
            public string FileName { get; set; }
            public int ContentLength{ get; set; }
            public byte[] Content { get;set; }
        }

    }
}
