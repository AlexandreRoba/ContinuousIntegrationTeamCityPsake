using Xunit;

namespace WebApplication.Controllers
{

    public class HomeControllerTest
    {
        [Fact]
        public void About_WhenCalled_ShouldAddMessageToTheViewBag()
        {
            var sut = new HomeController();

            sut.About();

            Assert.NotEmpty(sut.ViewBag.Message);
        }
    }
}