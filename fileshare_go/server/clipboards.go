package server

import (
	"sync"
	"sync/atomic"
)

type ClipBoards struct {
	mux sync.RWMutex

	increId  atomic.Int64
	contents []Board
}

type Board struct {
	ID      int64  `json:"id,omitempty"`
	Content string `json:"content,omitempty"`
}

func (c *ClipBoards) Add(content string) int64 {
	c.mux.Lock()
	defer c.mux.Unlock()
	id := c.increId.Add(1)
	c.contents = append(c.contents, Board{Content: content, ID: id})
	return id
}
func (c *ClipBoards) List() []Board {
	c.mux.RLock()
	defer c.mux.RUnlock()
	data := make([]Board, 0, len(c.contents))
	for i := len(c.contents) - 1; i >= 0; i-- {
		data = append(data, c.contents[i])
	}
	return data
}
func (c *ClipBoards) DeleteAndLoad(id int64) (result string, delete bool) {
	c.mux.Lock()
	defer c.mux.Unlock()
	if id <= 0 {
		c.contents = nil
		return "", true
	}
	data := make([]Board, 0, len(c.contents))
	for _, board := range c.contents {
		if board.ID == id {
			result = board.Content
			delete = true
			continue
		}
		data = append(data, board)
	}
	c.contents = data
	return
}
