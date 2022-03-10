using InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Web.Builders.Model.Cases
{
    public class CaseImageBuilder : IBuilder<CaseImage>
    {
        public Case Case { get; set; }
        public int? ImageId { get; set; }
        public short? ImageSequence { get; set; }
        public int? ImageType { get; set; }
        public string ContentType { get; set; }
        public string ImageDescription { get; set; }
        public bool IncludeInCase { get; set; }

        public CaseImage Build()
        {
            var imageId = ImageId ?? Fixture.Integer();
            var imageType = ImageType ?? Fixture.Integer();
            var @case = Case ?? new CaseBuilder().Build();

            var caseImage = new CaseImage(
                                          @case,
                                          imageId,
                                          ImageSequence ?? Fixture.Short(), imageType)
            {
                Image = new Image(imageId)
                {
                    ImageData = new byte[] { }
                },
                CaseImageDescription = Fixture.String()
            };

            if (!string.IsNullOrEmpty(ContentType) || !string.IsNullOrEmpty(ImageDescription))
            {
                caseImage.Image.Detail = new ImageDetail
                {
                    ContentType = ContentType ?? Fixture.String(),
                    ImageDescription = ImageDescription ?? Fixture.String(),
                    ImageId = imageId
                };
            }

            caseImage.Case = @case;
            caseImage.Case.CaseImages.Add(caseImage);

            return caseImage;
        }
    }

    public static class CaseImageBuilderEx
    {
        public static CaseImageBuilder WithImageDetail(this CaseImageBuilder builder, string contentType, string imageDescription)
        {
            builder.ImageDescription = imageDescription;
            builder.ContentType = contentType;
            return builder;
        }
    }
}