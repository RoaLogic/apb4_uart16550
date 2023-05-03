/////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.          //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.    //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'    //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.    //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'    //
//                                             `---'               //
//             Reset signal control                                //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
//             Copyright (C) 2023 Roa Logic BV                     //
//             www.roalogic.com                                    //
//                                                                 //
//     This source file may be used and distributed without        //
//   restriction provided that this copyright statement is not     //
//   removed from the file and that any derivative work contains   //
//   the original copyright notice and the associated disclaimer.  //
//                                                                 //
//      THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY        //
//   EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED     //
//   TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS     //
//   FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR        //
//   OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,           //
//   INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES      //
//   (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE     //
//   GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR          //
//   BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF    //
//   LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT    //
//   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT    //
//   OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE           //
//   POSSIBILITY OF SUCH DAMAGE.                                   //
//                                                                 //
/////////////////////////////////////////////////////////////////////
/*!
 * @file reset.hpp
 * @author Bjorn Schouteten
 * @brief Clock object
 * @version 0.1
 * @date 03-may-2023
 * @copyright See beginning of file
 */

#include <observer.hpp>

#ifndef RESET_HPP
#define RESET_HPP

namespace RoaLogic
{
namespace test
{
    /**
     * @class cReset
     * @author Bjorn Schouteten
     * @brief Class to control a single reset input of a design
     * @version 0.1
     * @date 03-May-2023
     *
     */
    class cReset : public cObserver
    {
        private:
        uint8_t&    _reset;             //!< Points to reset input of device under test
        uint32_t    _tickCountAssert;   //!< Tickcount to assert the reset pin
        uint32_t    _tickCountDeassert; //!< Tickcount to deassert the reset pin
        vluint64_t  _tickCount;

        public:
        /**
         * @brief Construct a new cReset object
         * 
         * @param[in] reset             The reset pin 
         * @param[in] tickCountAssert   The tickcount to assert a reset
         * @param[in] tickCountDeassert The tickcount to deassert a reset
         */
        cReset(uint8_t& reset, uint32_t tickCountAssert, uint32_t tickCountDeassert) :
            _reset(reset),
            _tickCountAssert(tickCountAssert),
            _tickCountDeassert(tickCountDeassert)
        {
            _tickCount = 0;
            _reset = 1;
        }

        /**
         * @brief Destroy the cReset object
         * 
         */
        ~cReset()
        {

        }

        /**
         * @brief Notify event
         * @details Receive notify events 
         * 
         * Only handle rising edge of the clock 
         * When the _tickCount is between the _tickCountAssert & _tickCountDeassert then 
         * assert a reset in any other case deassert the reset
         * 
         * @param[in] aEvent    The event which happend
         * @return Always returns success
         */
        eErrorCode notify(eEvent aEvent)
        {
            if(aEvent == eEvent::risingEdge)
            {
                _tickCount++;

                if(_tickCount >= _tickCountAssert && _tickCount <_tickCountDeassert)
                {
                    if(_reset == 1)
                    {
                        _reset = 0;
                        std::cout << "RESET_H - Assert reset:\n";
                    }                    
                }
                else
                {
                    if(_reset == 0)
                    {
                        _reset = 1;
                        std::cout << "RESET_H - Deassert reset:\n";
                    }                    
                }
            }

            return eErrorCode::success;
        }

    };


}    
}


#endif
